import 'package:flutter/material.dart';
import '../../localization/localization.dart';
import '../customization/cloud_business_intake.dart';

enum GovernanceFailure { authentication, unavailable, invalid, conflict, network }
class GovernanceException implements Exception {
  const GovernanceException(this.failure);
  final GovernanceFailure failure;
}
enum ReportReason { copyright, abuse, sexualContent, violence, spam, other }
extension ReportReasonCode on ReportReason {
  String get code => this == ReportReason.sexualContent ? 'sexual_content' : name;
}
class ContentReport {
  ContentReport.fromJson(Map<String,dynamic> value)
      : id=value['id'] as String, status=value['status'] as String,
        resolution=value['resolution'] as String;
  final String id, status, resolution;
}
typedef GovernanceRequest = Future<CloudBusinessResponse> Function(String method, String path, {Map<String,dynamic>? document});
class ContentGovernanceRepository {
  static final changes = ValueNotifier<int>(0);
  ContentGovernanceRepository({GovernanceRequest? request, CloudBusinessIntake? intake})
      : _request=request ?? ((method,path,{document}) => (intake ?? CloudBusinessIntake.instance).contentRequest(method,path,document:document));
  final GovernanceRequest _request;
  Future<Map<String,dynamic>> _call(String method,String path,{Map<String,dynamic>? document}) async {
    try {
      final response=await _request(method,path,document:document);
      if(response.statusCode>=200 && response.statusCode<300) return response.body;
      throw GovernanceException(switch(response.statusCode) {
        401 => GovernanceFailure.authentication,
        404 => GovernanceFailure.unavailable,
        400 => GovernanceFailure.invalid,
        409 => GovernanceFailure.conflict,
        _ => GovernanceFailure.network,
      });
    } on GovernanceException { rethrow; } catch (_) { throw const GovernanceException(GovernanceFailure.network); }
  }
  Future<ContentReport> report(String packageId,ReportReason reason,String details) async => ContentReport.fromJson(await _call('POST','/v1/me/reports',document:{'packageId':packageId,'reason':reason.code,'details':details}));
  Future<List<ContentReport>> reports() async => ((await _call('GET','/v1/me/reports'))['items'] as List).map((v)=>ContentReport.fromJson(v as Map<String,dynamic>)).toList();
  Future<Set<String>> blocks() async => ((await _call('GET','/v1/me/blocks'))['items'] as List).map((v)=>v['creatorId'] as String).toSet();
  Future<String> block(String packageId) async {
    final id = (await _call('POST','/v1/me/blocks',document:{'packageId':packageId}))['creatorId'] as String;
    changes.value++;
    return id;
  }
  Future<void> unblock(String creatorId) async {
    await _call('DELETE','/v1/me/blocks/${Uri.encodeComponent(creatorId)}');
    changes.value++;
  }
}

String governanceError(BuildContext context, Object error) {
 final l=context.l10n;
 return switch(error is GovernanceException ? error.failure : GovernanceFailure.network) {
  GovernanceFailure.authentication=>l.governanceAuthError,
  GovernanceFailure.unavailable=>l.governanceUnavailableError,
  GovernanceFailure.invalid=>l.governanceInvalidError,
  GovernanceFailure.conflict=>l.governanceConflictError,
  GovernanceFailure.network=>l.governanceNetworkError,
 };
}
class ContentGovernanceActions extends StatefulWidget {
 const ContentGovernanceActions({super.key,required this.packageId,this.creatorId,this.onBlocked,this.repository});
 final String packageId;
 final String? creatorId;
 final ValueChanged<String>? onBlocked;
 final ContentGovernanceRepository? repository;
 @override State<ContentGovernanceActions> createState()=>_ContentGovernanceActionsState();
}
class _ContentGovernanceActionsState extends State<ContentGovernanceActions> {
 bool busy=false;
 ContentGovernanceRepository get repository=>widget.repository ?? ContentGovernanceRepository();
 Future<void> perform(Future<void> Function() operation) async {
  setState(()=>busy=true);
  try { await operation(); } catch(error) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(governanceError(context,error)))); }
  finally { if(mounted) setState(()=>busy=false); }
 }
 Future<void> report() async {
  var details='';var reason=ReportReason.copyright;
  final accepted=await showDialog<bool>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,update){
   final l=context.l10n;final labels=[l.governanceCopyright,l.governanceAbuse,l.governanceSexual,l.governanceViolence,l.governanceSpam,l.governanceOther];
   return AlertDialog(title:Text(l.governanceReport),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    DropdownButton<ReportReason>(isExpanded:true,value:reason,items:ReportReason.values.map((v)=>DropdownMenuItem(value:v,child:Text(labels[v.index]))).toList(),onChanged:(v){if(v!=null) update(()=>reason=v);}),
    TextField(onChanged:(value)=>details=value,maxLength:2000,maxLines:4,decoration:InputDecoration(labelText:l.governanceDetails)),Text(l.governanceReportNote),
   ])),actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:Text(l.governanceCancel)),FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:Text(l.governanceSubmit))]);
  }));
  final text=details;if(accepted!=true || !mounted)return;
  await perform(() async { final result=await repository.report(widget.packageId,reason,text);if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.l10n.governanceReceived(result.id)))); });
 }
 Future<void> block() async {
  final accepted=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text(context.l10n.governanceBlock),content:Text(context.l10n.governanceBlockNote),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(context.l10n.governanceCancel)),FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(context.l10n.governanceBlock))]));
  if(accepted!=true || !mounted)return;
  await perform(() async {final id=await repository.block(widget.packageId);if(mounted){widget.onBlocked?.call(id);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.l10n.governanceBlocked)));}});
 }
 @override Widget build(BuildContext context)=>Wrap(spacing:8,children:[TextButton.icon(onPressed:busy?null:report,icon:const Icon(Icons.flag_outlined),label:Text(context.l10n.governanceReport)),if(widget.creatorId!=null)TextButton.icon(onPressed:busy?null:block,icon:const Icon(Icons.block),label:Text(context.l10n.governanceBlock)),if(busy)const CircularProgressIndicator()]);
}

class ContentGovernancePage extends StatefulWidget {
 const ContentGovernancePage({super.key,this.repository,this.onBlocksChanged});
 final ContentGovernanceRepository? repository;
 final VoidCallback? onBlocksChanged;
 @override State<ContentGovernancePage> createState()=>_ContentGovernancePageState();
}
class _ContentGovernancePageState extends State<ContentGovernancePage> {
 late final repository=widget.repository ?? ContentGovernanceRepository();
 late Future<(List<ContentReport>,Set<String>)> data=load();
 Future<(List<ContentReport>,Set<String>)> load() async =>(await repository.reports(),await repository.blocks());
 void refresh()=>setState(()=>data=load());
 @override Widget build(BuildContext context) {
  final l=context.l10n;
  return Scaffold(appBar:AppBar(title:Text(l.governanceTitle),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh),tooltip:l.governanceRefresh)]),body:FutureBuilder<(List<ContentReport>,Set<String>)>(future:data,builder:(context,snapshot){
   if(snapshot.hasError)return Center(child:Text(governanceError(context,snapshot.error!)));
   if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
   final (reports,blocks)=snapshot.data!;
   return ListView(padding:const EdgeInsets.all(16),children:[Text(l.governanceReports,style:Theme.of(context).textTheme.titleLarge),if(reports.isEmpty)Text(l.governanceEmpty),...reports.map((r)=>ListTile(title:Text(r.id),subtitle:Text('${switch(r.status){'received'=>l.governanceStatusReceived,'in_review'=>l.governanceStatusReview,'action_taken'=>l.governanceStatusAction,_=>l.governanceStatusNoViolation}}\n${r.resolution}'))),Text(l.governanceBlocks,style:Theme.of(context).textTheme.titleLarge),if(blocks.isEmpty)Text(l.governanceEmpty),...blocks.map((id)=>ListTile(title:Text(id),trailing:TextButton(child:Text(l.governanceUnblock),onPressed:() async {try{await repository.unblock(id);if(mounted){widget.onBlocksChanged?.call();refresh();}}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(governanceError(context,e))));}})))]);
  }));
 }
}
