"""Merge reviewed feature ARB fragments; Flutter gen-l10n generates typed APIs."""
import json, pathlib
root=pathlib.Path(__file__).resolve().parents[1]
catalogs={}
for locale in ['en','zh','de','es','ja']:
    data={'@@locale':locale}
    for path in sorted((root/'lib/l10n/fragments').glob('*_'+locale+'.json')):
        fragment=json.loads(path.read_text(encoding='utf-8'))
        duplicate=(data.keys() & fragment.keys())-{'@@locale'}
        if duplicate:raise ValueError(f'Duplicate keys {path}: {duplicate}')
        data.update(fragment)
    catalogs[locale]=data
keys=lambda d:{k for k in d if not k.startswith('@')}
for locale in catalogs:
    if keys(catalogs['en']) != keys(catalogs[locale]):
        raise ValueError(f'{locale} keys differ from English')
for locale,data in catalogs.items():
    (root/f'lib/l10n/app_{locale}.arb').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Merged messages per language:',len(keys(catalogs['en'])))
