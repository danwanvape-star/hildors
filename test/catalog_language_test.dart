import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hildors_cockpit/src/features/community/remote_catalog_repository.dart';

void main() {
  final legacy={'id':'role','title':'角色','description':'故事','source':'hildors','status':'published','format':'single','tags':['神话传说'],
    'clips':[{'id':'clip','title':'待机'}]};
  test('legacy metadata remains readable',(){
    final item=RemoteCatalogPackage.fromJson(legacy);expect(item.title,'角色');expect(item.tags,['神话传说']);
  });
  test('localized fields and stable tag IDs are used without discarding fallback data',(){
    final item=RemoteCatalogPackage.fromJson({...legacy,
      'localized':{'title':'Star','description':'A story','missingFields':[]},
      'tagDetails':[{'id':'genre-1','name':'神话传说','localized':{'name':'Mythology'}}],
      'clips':[{'id':'clip','title':'待机','localized':{'title':'Idle'}}]});
    expect(item.title,'Star');expect(item.description,'A story');expect(item.tags,['Mythology']);expect(item.clips.single.title,'Idle');
  });
  test('catalog sends explicitly selected language to API',() async {
    Uri? seen;
    final repo=RemoteCatalogRepository('https://api.hildors.com',fetch:(uri) async {seen=uri;return jsonEncode({'items':[legacy]});});
    await repo.load(language:'en');expect(seen!.queryParameters['lang'],'en');
  });
}
