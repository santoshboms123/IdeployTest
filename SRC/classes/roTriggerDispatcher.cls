/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public class roTriggerDispatcher {

    public enum handlerClass {roResourceAllocationTriggerHandler, roResourceAvailableHoursTriggerHandler, 
        roResourceTriggerHandler, roResourceUtilizationTriggerHandler, roResourceOptimizeSecurityTriggerHandler, 
        roResourceSkillsTriggerHandler, roReservationTriggerHandler}

    public static void run(handlerClass handlerClassInstance){
        roITriggerHandler handler;

        if(handlerClassInstance == handlerClass.roResourceAllocationTriggerHandler){
            handler = new roResourceAllocationTriggerHandler();
        }
        else if(handlerClassInstance == handlerClass.roResourceAvailableHoursTriggerHandler){
            handler = new roResourceAvailableHoursTriggerHandler();
        }
        else if(handlerClassInstance == handlerClass.roResourceTriggerHandler){
            handler = new roResourceTriggerHandler();
        }
        else if(handlerClassInstance == handlerClass.roResourceUtilizationTriggerHandler){
            handler = new roResourceUtilizationTriggerHandler();
        }
        else if(handlerClassInstance == handlerClass.roResourceOptimizeSecurityTriggerHandler){
            handler = new roResourceOptimizeSecurityTriggerHandler();
        }
        else if(handlerClassInstance == handlerClass.roResourceSkillsTriggerHandler){
            handler = new roResourceSkillsTriggerHandler();
        }
        else if(handlerClassInstance == handlerClass.roReservationTriggerHandler){
            handler = new roReservationTriggerHandler();
        }
        
        //Check trigger context from trigger operation type
        switch on Trigger.operationType {
                 
            when BEFORE_INSERT {
                //Invoke before insert trigger handler
                handler.beforeInsert(trigger.new);
            }
            when AFTER_INSERT {
                //Invoke after insert trigger handler
                handler.afterInsert(trigger.newMap);
            }
            when BEFORE_UPDATE {
                //Invoke before update trigger handler
                handler.beforeUpdate(trigger.newMap, trigger.oldMap);
            }
            when AFTER_UPDATE {
                //Invoke after update trigger handler
                handler.afterUpdate(trigger.newMap, trigger.oldMap);
            }
            when BEFORE_DELETE {
                //Invoke before delete trigger handler
                handler.beforeDelete(trigger.oldMap);
            }
            when AFTER_DELETE {
                //Invoke after delete trigger handler
                handler.afterDelete(trigger.oldMap);
            }
        }
    }
}