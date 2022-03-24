trigger FeedCommentTrigger on FeedComment (after update,after insert,before insert,before delete,before update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        FeedCommentTriggerHandler.afterUpdate(Trigger.New, Trigger.oldMap);
    }
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            FeedCommentTriggerHandler.beforeDelete(Trigger.old, Trigger.oldMap);
        }
        if(FeedCommentTriggerHandler.isFirstTime) {
            if(Trigger.isInsert || Trigger.isUpdate){
                FeedCommentTriggerHandler.isFirstTime = false;
                FeedCommentTriggerHandler.feedcommentURLUpdate(Trigger.New);
            }
        }
        if(Trigger.isUpdate) {
            FeedCommentTriggerHandler.beforeUpdate(Trigger.old,Trigger.oldMap, Trigger.new, Trigger.newMap); 
        }
    }
}