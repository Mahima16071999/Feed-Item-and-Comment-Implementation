trigger FeedItemTrigger on FeedItem (after update,before insert,before delete,before update) {
    
    if(Trigger.isAfter && Trigger.isUpdate){
        FeedItemTriggerHandler.afterUpdate(Trigger.New, Trigger.oldMap);
    }
    
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            FeedItemTriggerHandler.beforeDelete(Trigger.old, Trigger.oldMap);
        }
        if(FeedItemTriggerHandler.isFirstTime) {
            if(Trigger.isInsert || Trigger.isUpdate){
                FeedItemTriggerHandler.isFirstTime = false;
                FeedItemTriggerHandler.feedURLUpdate(Trigger.New);
            }
            if(Trigger.isUpdate) {
                FeedItemTriggerHandler.beforeUpdate(Trigger.old,Trigger.oldMap, Trigger.new, Trigger.newMap);
            }
        }
    } 
}