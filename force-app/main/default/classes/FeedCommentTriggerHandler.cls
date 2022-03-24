public class FeedCommentTriggerHandler{
    public static Boolean isFirstTime = true;
    Public Static String currentUserId;
    public static String appendToURL = System.label.FeedItemUrlString;
    Public Static String networkIdValue = System.Label.NewtorkIdValue;
    public static List<String> domainList = System.label.Commmunity_URL_Feed_Domain.split(',');
    Public Static String permissionSetName = System.Label.Permission_Set_Name;
    public static String adminPermissionSet = System.Label.Enphase_Community_Moderator_Admin_Permission_Set;
    public static String appendToURLEncoded = System.label.FeedItemUrlString_Encoded; 
    Public Static List<PermissionSetAssignment> permissionSetAssignList = new List<PermissionSetAssignment>();
    
    public static List<FeedComment> checkIsNetworkComment(List<FeedComment> newList){
        List<FeedComment> returnList= new List<FeedComment>();
        map<String,List<feedComment>> tempMap = new map<String,List<feedComment>>();
        set<id> setIdList = new set<id>();
        for(FeedComment feedCommentRec : newList){
            setIdList.add(feedCommentRec.FeedItemId);
            if(tempMap.containsKey(feedCommentRec.FeedItemId)){
                List<FeedComment> tempList =new List<FeedComment>();
                tempList =tempMap.get(feedCommentRec.FeedItemId);
                tempList.add(feedCommentRec);
                tempMap.put(feedCommentRec.FeedItemId,tempList);
            }else{
                List<FeedComment> tempList =new List<FeedComment>();
                tempList.add(feedCommentRec);
                tempMap.put(feedCommentRec.FeedItemId,tempList);
            }
        }
        List<FeedItem> allFeedItem=[Select id,NetworkScope from feedItem where id in :setIdList and NetworkScope=:networkIdValue];
        for(FeedItem tempFeedRec : allFeedItem){
            returnList.addAll(tempMap.get(tempFeedRec.id));
        }
        return returnList;
    }
    public static void afterUpdate(List<FeedComment> newList, Map<Id, FeedComment> oldMap){
        
    }
    
    public static void beforeDelete(List<FeedComment> oldList, Map<Id, FeedComment> oldMap){
        
        currentUserId = UserInfo.getUserId();
        List<PermissionSet> permissionSetList =  [SELECT Label, Name, Id, ProfileId FROM PermissionSet where name =: permissionSetName];
        if(permissionSetList.size()>0){
            permissionSetAssignList= [SELECT AssigneeId, PermissionSetGroupId, PermissionSetId, Id FROM PermissionSetAssignment WHERE PermissionSetId=:permissionSetList[0].id AND AssigneeId=:currentUserId];
        }
        
        // Check if it is moderate user
        if(permissionSetAssignList.size()>0){
            List<PermissionSet> permissionSet = [SELECT Label, Name, Id, ProfileId FROM PermissionSet where name =: adminPermissionSet];
            System.debug('permissionSet=> '+permissionSet.size());
            if(permissionSet.size() > 0) {
                List<PermissionSetAssignment > assignedPermissionSetList= [SELECT AssigneeId, PermissionSetGroupId, PermissionSetId, Id FROM PermissionSetAssignment WHERE PermissionSetId=:permissionSet[0].Id AND AssigneeId=:currentUserId];
                if(assignedPermissionSetList.size() > 0) {
                    //Perform Action
                } else {
                    for(Integer i=0; i<oldList.size(); i++) {
                        if(oldList[i].CreatedById != UserInfo.getUserId()) {
                            System.debug('in if');
                            oldList[i].addError('You do not have the permission to delete the comments!');
                        } 
                    }
                }
            }
        }        
    }
    
    public static void feedcommentURLUpdate(List<FeedComment> newList){
        List<FeedComment> newURLList = new  List<FeedComment>();
        newList = checkIsNetworkComment(newList);
        for(FeedComment feedCommentRec : newList){
            if(feedCommentRec.CommentBody != null){
                if (feedCommentRec.CommentBody.contains('http')){ 
                    for(integer i =0 ;i<domainList.size();i++){
                        if(feedCommentRec.CommentBody.contains(domainList[i])){
                            newURLList.add(feedCommentRec);
                        }   
                    }
                }
            }
        }
        if(newURLList.size()>0){
            feedURLsFromBody(newURLList);
        }
        
    } 
    
    @future(callout=true)
    public static void futuretest(Id feedCommentId, String str) {
        System.debug('id==> '+feedCommentId+' ::: '+str);
        List<FeedComment> item = [Select Id, CommentBody from FeedComment where Id=: feedCommentId LIMIT 1];
        System.debug('item => '+item);
    }
    public static List<FeedComment> feedURLsFromBody (List<FeedComment> newList){
        for(FeedComment feedCommentRec : newList){
            Set<String> etrctURL = extractURLsFromBody(feedCommentRec.CommentBody);
            Map<String,String> mapURLValues= prepareURLDataValues(etrctURL);
            String finalFeedCommentRecordBody = replaceURLWithDataURL(feedCommentRec.CommentBody,etrctURL,mapURLValues);
            System.debug('etrctURL'+etrctURL);
            feedCommentRec.CommentBody = finalFeedCommentRecordBody;
        }
        return newList;
        
    }
    
    public static Set<String> extractURLsFromBody (String templateString){
        
        Set<String> urlSet = new Set<String>();
        if(String.isNotEmpty(templateString)){
            String rawUrl; 
            String tempURL ;
            String mainURL ;
            templateString=templateString.replace('</p>','');
            templateString = templateString + ' ';
            templateString = templateString + '</p>';
            templateString = templateString.replace('>', '> ');
            templateString = templateString.replace('<', ' <');
            
            Pattern myPattern = Pattern.compile('http(\\S+)\\s');
            Matcher myMatch = myPattern.matcher(templateString);
            while (myMatch.find()) {
                rawUrl = myMatch.group();
                mainURL=rawUrl.replace('"','').replace('</a>','').trim();
                mainURL=mainURL.replace('>', '');
                tempURL = mainURL.toLowercase();
                for(integer i =0 ;i<domainList.size();i++){
                    if(tempURL.indexOf(domainList[i]) != -1){
                        urlSet.add(mainURL);
                    }
                }
            }   
        }
        return urlSet;
        
    }
    
    public static Map<String, String> prepareURLDataValues(Set<String> urlSet){
        
        Map<String, String> preparedURLValueMap = new Map<String, String>();
        String finalURL;
        for(String key: urlSet){
            if((!key.contains(appendToURL)) && (!key.contains(appendToURLEncoded))){
                if(key.contains('?')){
                    finalURL = key + '&'+appendToURL.trim();    
                }
                else{
                    finalURL = key + '?' + appendToURL.trim();      
                }
            }
            else{
                finalURL = key;   
            }
            preparedURLValueMap.put(key,finalURL)  ; 
        }
        return preparedURLValueMap;
        
    }
    
    public static String replaceURLWithDataURL(String templateString, Set<String> urlSet, Map<String, String> uRLsDataValues){  
        
        for(String mergeF1 : urlSet){
            String findString = '"' + mergeF1 + '"';
            String replaceString = '"' + (uRLsDataValues.get(mergeF1)) + '"';
            templateString = templateString.replace(mergeF1, (uRLsDataValues.get(mergeF1)));
            //templateString = templateString.replace(findString,replaceString);
        }
        System.debug('templateString'+templateString);
        return templateString;
        
    }
    
    public static void beforeUpdate(List<FeedComment> oldList, Map<Id, FeedComment> oldMap, List<FeedComment> newList, Map<Id, FeedComment> newMap) {
        currentUserId = UserInfo.getUserId();
        List<PermissionSet> permissionSetList =  [SELECT Label, Name, Id, ProfileId FROM PermissionSet where name =: permissionSetName];
        if(permissionSetList.size()>0){
            permissionSetAssignList= [SELECT AssigneeId, PermissionSetGroupId, PermissionSetId, Id FROM PermissionSetAssignment WHERE PermissionSetId=:permissionSetList[0].id AND AssigneeId=:currentUserId];
            if(permissionSetAssignList.size() > 0) {
                List<PermissionSet> permissionSet = [SELECT Label, Name, Id, ProfileId FROM PermissionSet where name =: adminPermissionSet];
                if(permissionSet.size() > 0) {
                    List<PermissionSetAssignment > assignedPermissionSetList= [SELECT AssigneeId, PermissionSetGroupId, PermissionSetId, Id FROM PermissionSetAssignment WHERE PermissionSetId=:permissionSet[0].Id AND AssigneeId=:currentUserId];
                    System.debug('assignedPermissionSetList=> '+ assignedPermissionSetList);
                    System.debug('oldMap=> '+ oldMap);
                    if(assignedPermissionSetList.size() <= 0){
                        for(Integer i=0; i< newList.size(); i++) {
                            System.debug('if keyss=> '+ newMap.get(newList[i].Id));
                            if(oldMap.get(newList[i].Id).CommentBody != newMap.get(newList[i].Id).CommentBody && newMap.get(newList[i].Id).CreatedById != UserInfo.getUserId()){
                                newList[i].addError('You do not have the permission to edit and delete the comments!'); 
                            }
                        }
                    } else {
                        for(Integer i=0; i< newList.size(); i++) {
                            System.debug('keyss=> '+ oldMap.get(newList[i].Id));
                            if(oldMap.get(newList[i].Id).CommentBody != newMap.get(newList[i].Id).CommentBody && newMap.get(newList[i].Id).CreatedById != UserInfo.getUserId()){
                                newList[i].addError('You do not have the permission to edit the comments!'); 
                            }
                        }
                    }
                } 
            }
            
        }
        
    } 
}