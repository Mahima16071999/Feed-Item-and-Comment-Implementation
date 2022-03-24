public with sharing class FeedItemTriggerHandler{
    Public Static String currentUserId;
    Public Static String permissionSetName = System.Label.Permission_Set_Name;
    public static String adminPermissionSet = System.Label.Enphase_Community_Moderator_Admin_Permission_Set;
    Public Static List<PermissionSetAssignment> permissionSetAssignList = new List<PermissionSetAssignment>();
    Public Static String networkIdValue = System.Label.NewtorkIdValue;
    public static Boolean isFirstTime = true;
    public static String appendToURL = System.label.FeedItemUrlString;
    public static String appendToURLEncoded = System.label.FeedItemUrlString_Encoded; 
    public static List<String> domainList = System.label.Commmunity_URL_Feed_Domain.split(',');
    public static void afterUpdate(List<FeedItem> newList, Map<Id, FeedItem> oldMap){
        
    }
    public static void beforeDelete(List<FeedItem> oldList, Map<Id, FeedItem> oldMap){
        
        currentUserId = UserInfo.getUserId();
        List<PermissionSet> permissionSetList =  [SELECT Label, Name, Id, ProfileId FROM PermissionSet where name =: permissionSetName];
        if(permissionSetList.size()>0){
            permissionSetAssignList= [SELECT AssigneeId, PermissionSetGroupId, PermissionSetId, Id FROM PermissionSetAssignment WHERE PermissionSetId=:permissionSetList[0].id AND AssigneeId=:currentUserId];
        }
        
        system.debug('permissionSetAssignList====>'+permissionSetAssignList);
        // Check if it is moderate user
        if(permissionSetAssignList.size()>0){
            //Check if the user can delete post
            List<PermissionSet> permissionSet = [SELECT Label, Name, Id, ProfileId FROM PermissionSet where name =: adminPermissionSet];
            System.debug('permissionSet=> '+permissionSet.size());
            if(permissionSet.size() > 0) {
                List<PermissionSetAssignment > assignedPermissionSetList= [SELECT AssigneeId, PermissionSetGroupId, PermissionSetId, Id FROM PermissionSetAssignment WHERE PermissionSetId=:permissionSet[0].Id AND AssigneeId=:currentUserId];
                if(assignedPermissionSetList.size() > 0) {
                    //Perform action
                } else {
                    for(Integer i=0; i<oldList.size(); i++) {
                        if(oldList[i].CreatedById != UserInfo.getUserId()) {
                            oldList[i].addError('You do not have the permission delete the posts!');
                        }
                    }
                }
            }
            
        }
    }
    
    public static void feedURLUpdate(List<FeedItem> newList){
        
        List<FeedItem> newURLList = new  List<FeedItem>();
        for(FeedItem feedItemRec : newList){
            If(feedItemRec.NetworkScope ==networkIdValue){
                System.debug('feedItemRec.Body'+feedItemRec.Body);
                if(feedItemRec.Body != null){
                    if (feedItemRec.Body.contains('http')){ 
                        for(integer i =0 ;i<domainList.size();i++){
                            if(feedItemRec.Body.contains(domainList[i])){
                                newURLList.add(feedItemRec);
                            }  
                        }
                    }
                }
            }
        }
        if(newURLList.size()>0){
            feedURLsFromBody(newURLList);
        }
        
    }
    public static List<FeedItem> feedURLsFromBody (List<FeedItem> newList){
        
        for(FeedItem feedItemRec : newList){
            System.debug('newList '+String.valueof(newList));

            Set<String> etrctURL = extractURLsFromBody(feedItemRec.Body);
            Map<String,String> mapURLValues= prepareURLDataValues(etrctURL);
            String finalFeedItemRecordBody = replaceURLWithDataURL(feedItemRec.Body,etrctURL,mapURLValues);
            System.debug('etrctURL'+etrctURL);
            feedItemRec.Body = finalFeedItemRecordBody;
        }
        return newList;
        
    }
    
    public static Set<String> extractURLsFromBody (String templateString){
                    System.debug('templateString1 '+String.valueof(templateString));

        Set<String> urlSet = new Set<String>();
        if(String.isNotEmpty(templateString)){
            String rawUrl; 
            String tempURL ;
            String mainURL ;
            templateString = templateString.replace('</p>','');
                        System.debug('templateString1 '+String.valueof(templateString));

            templateString = templateString + ' ';
            templateString = templateString + '</p>';
            templateString = templateString.replace('>', '> ');
                        System.debug('templateString2 '+String.valueof(templateString));

            templateString = templateString.replace('<', ' <');
                        System.debug('templateString3 '+String.valueof(templateString));

            Pattern myPattern = Pattern.compile('http(\\S+)\\s');
            Matcher myMatch = myPattern.matcher(templateString);
            while (myMatch.find()) {
                rawUrl = myMatch.group();
                mainURL=rawUrl.replace('"','').replace('</a>','').trim();
                mainURL=mainURL.replace('>', '');
                tempURL = mainURL.toLowercase();
                            System.debug('tempURL '+tempURL);

                for(integer i =0 ;i<domainList.size();i++){
                    if(tempURL.indexOf(domainList[i]) != -1){
                        System.debug('mainURL'+mainURL);
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
        System.debug('urlSet==='+urlSet);
        for(String key: urlSet){
            System.debug('key'+key);
            if((!key.contains(appendToURL)) && (!key.contains(appendToURLEncoded))){
                if(key.contains('?')){
                    finalURL = key + '&'+appendToURL.trim();    
                }
                else{
                    finalURL = key + '?' + appendToURL.trim();      
                }
                System.debug('finalURL=='+finalURL);
            }
            else{
                finalURL = key;
                System.debug('finalURL'+finalURL);
            }
            preparedURLValueMap.put(key,finalURL)  ; 
        }
        return preparedURLValueMap;
        
    }
    
    public static String replaceURLWithDataURL(String templateString, Set<String> urlSet, Map<String, String> uRLsDataValues){  
        
        for(String mergeF1 : urlSet){
            System.debug('templateStrininloop'+templateString);
            System.debug('mergeF1'+mergeF1);
            System.debug('uRLsDataValues.get(mergeF1)'+uRLsDataValues.get(mergeF1));
            String findString = '"' + mergeF1 + '"';
            String replaceString = '"' + (uRLsDataValues.get(mergeF1)) + '"';
            templateString = templateString.replace(mergeF1, (uRLsDataValues.get(mergeF1)));
            //templateString = templateString.replace(findString,replaceString);
            
        }
        System.debug('templateString'+templateString);
        return templateString;
        
    }
    
    public static void beforeUpdate(List<FeedItem> oldList, Map<Id, FeedItem> oldMap, List<FeedItem> newList, Map<Id, FeedItem> newMap) {
        currentUserId = UserInfo.getUserId();
        for(Integer i=0; i< newList.size(); i++) {
            if(oldMap.get(newList[i].Id).Title != newMap.get(newList[i].Id).Title || oldMap.get(newList[i].Id).Body != newMap.get(newList[i].Id).Body ){
                newList[i].addError('You do not have the permission to edit the posts!'); 
                System.debug('in if');
            } else {
                System.debug('else');
            }
        }
        
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
                            if(oldMap.get(newList[i].Id).Title != newMap.get(newList[i].Id).Title || oldMap.get(newList[i].Id).Body != newMap.get(newList[i].Id).Body  && newMap.get(newList[i].Id).CreatedById != UserInfo.getUserId()){
                                newList[i].addError('You do not have the permission to edit and delete the comments!'); 
                            }
                        }
                    } else {
                        for(Integer i=0; i< newList.size(); i++) {
                            System.debug('keyss=> '+ oldMap.get(newList[i].Id));
                            if(oldMap.get(newList[i].Id).Title != newMap.get(newList[i].Id).Title || oldMap.get(newList[i].Id).Body != newMap.get(newList[i].Id).Body  && newMap.get(newList[i].Id).CreatedById != UserInfo.getUserId()){
                                newList[i].addError('You do not have the permission to edit the comments!'); 
                            }
                        }
                    }
                } 
            }
            
        }
      
    }
    
    
}