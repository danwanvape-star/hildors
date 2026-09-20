"""Run only on the authorized server from the uniquely named staging directory."""
import pathlib,hashlib,json,sqlite3,subprocess,tempfile,shutil,tarfile,datetime,time,urllib.request
stage=pathlib.Path(__file__).resolve().parent
root=pathlib.Path('/opt/hildors/backend')
expected=json.loads((stage/'expected.json').read_text())
target=json.loads((stage/'target.json').read_text())
def verify():
 for name,digest in expected.items():
  path=root/name
  if digest is None:
   if path.exists():raise RuntimeError('Unexpected existing file: '+name)
  elif hashlib.sha256(path.read_bytes()).hexdigest()!=digest:raise RuntimeError('Online file changed: '+name)
 for name,digest in target.items():
  if hashlib.sha256((stage/name).read_bytes()).hexdigest()!=digest:raise RuntimeError('Candidate mismatch: '+name)
verify()
def snapshot(db):
 result={}
 for (table,) in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"):
  columns=[r[1] for r in db.execute('PRAGMA table_info("'+table+'")') if not(table=='operators' and r[1]=='must_change_password')]
  sql='SELECT '+','.join('"'+c+'"' for c in columns)+' FROM "'+table+'"'
  result[table]=sorted(repr(row) for row in db.execute(sql))
 return result
with tempfile.TemporaryDirectory(prefix='hildors-compatible-migration-') as temp:
 tmp=pathlib.Path(temp);shutil.copytree(root/'src',tmp/'src')
 for name in target:
  if name.startswith('src/'):shutil.copyfile(stage/name,tmp/name)
 with sqlite3.connect('file:/var/lib/hildors-api/catalog.sqlite?mode=ro',uri=True) as origin,sqlite3.connect(tmp/'clone.sqlite') as clone:origin.backup(clone);before=snapshot(clone)
 code='import {createStore} from '+json.dumps((tmp/'src/store.mjs').as_uri())+';const s=createStore('+json.dumps(str(tmp/'clone.sqlite'))+');if(!s.ready())throw Error("not ready");s.close();'
 subprocess.run(['node','--input-type=module','-e',code],check=True,capture_output=True)
 with sqlite3.connect(tmp/'clone.sqlite') as clone:
  if before!=snapshot(clone):raise RuntimeError('Migration changed existing data')
  if clone.execute('SELECT count(*) FROM operators WHERE must_change_password<>0').fetchone()[0]:raise RuntimeError('Existing account flags changed')
 print('Clone migration verified; existing rows/grants/password hashes unchanged')
verify()
backup=pathlib.Path('/var/backups/hildors')/('operator-hardening-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
backup.mkdir(mode=0o700)
with tarfile.open(backup/'code.tgz','w:gz') as archive:
 for name in target:
  if expected[name] is not None:archive.add(root/name,arcname=name)
# The old positional INSERT needs explicit columns to tolerate the additive column.
rollback_operator=(root/'src/operators.mjs').read_text().replace('INSERT INTO operators VALUES','INSERT INTO operators (id,username,display_name,password_hash,active,permissions,version,auth_version,created_at,updated_at) VALUES')
(backup/'operators-rollback-compatible.mjs').write_text(rollback_operator)
with sqlite3.connect('file:/var/lib/hildors-api/catalog.sqlite?mode=ro',uri=True) as origin,sqlite3.connect(backup/'catalog.sqlite') as copy:origin.backup(copy)
def rollback():
 with tarfile.open(backup/'code.tgz') as archive:
  for name in target:
   if expected[name] is not None:(root/name).write_bytes(archive.extractfile(name).read())
 (root/'src/operators.mjs').write_text(rollback_operator)
 subprocess.run(['systemctl','restart','hildors-team-staging.service'],check=True)
try:
 verify()
 for name in target:shutil.copyfile(stage/name,root/name)
 subprocess.run(['systemctl','restart','hildors-team-staging.service'],check=True)
 ready=False
 for attempt in range(30):
  try:
   with urllib.request.urlopen('http://127.0.0.1:8787/ready',timeout=2) as response:ready=response.status==200
   if ready:break
  except Exception:time.sleep(.3)
 if not ready:raise RuntimeError('Readiness failed')
 for name,digest in target.items():
  if hashlib.sha256((root/name).read_bytes()).hexdigest()!=digest:raise RuntimeError('Deployed hash mismatch')
 token=pathlib.Path('/etc/hildors/admin-token').read_text().strip()
 for path in ['/admin/me','/admin/operators','/admin/audit']:
  request=urllib.request.Request('http://127.0.0.1:8787'+path,headers={'Authorization':'Bearer '+token})
  with urllib.request.urlopen(request,timeout=5) as response:
   result=json.load(response)
   if path=='/admin/me' and result.get('actor',{}).get('isRoot') is not True:raise RuntimeError('Root identity changed')
   print(path,'HTTP',response.status)
except Exception:
 rollback();raise
print('DEPLOYED; readiness HTTP 200; manual backup:',backup)
