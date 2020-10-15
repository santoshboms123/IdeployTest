/************************************************************************ 
Author : Sukku
Details: 
    Purpose : roNotificationScheduler - A Schedulable Apex Class to Send proactive notification to the Resource Users. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
global class roNotificationScheduler implements schedulable{
     global void execute(SchedulableContext SC) {
     // mergeNumbers M = new mergeNumbers(); 
     ResourceOptimizerConfig__c ROC = ResourceOptimizerConfig__c.getOrgDefaults();
     Integer Interval = Integer.valueof(ROC.Allocation_alert_interval__c) ;
     datetime starttime = system.now().addMinutes(Interval);
     datetime endtime = starttime.addMinutes(Interval);
     system.debug('starttime'+starttime);
     system.debug('endtime'+endtime);
     system.debug('ALLOcs'+ [select id,name,subject__c,Resource__r.User__c,Allocated_Start_DateTime__c from Resource_Allocation__c where Resource__r.User__c != null AND Resource__r.Recieve_Allocation_Alerts__c = true]);
     List<Resource_Allocation__c> ALLallocations = New List<Resource_Allocation__c>();
         if(roSecurityHandler.checkField(new String[] {'subject__c','Allocated_Start_DateTime__c'},'Resource_Allocation__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
           roSecurityHandler.checkField(new String[] {'User__c','Recieve_Allocation_Alerts__c'},'Resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
           roSecurityHandler.checkObject('Resource_Allocation__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
           roSecurityHandler.checkObject('Resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
        ALLallocations = [select id,name,subject__c,Resource__r.User__c from Resource_Allocation__c where Allocated_Start_DateTime__c >= :starttime AND Allocated_Start_DateTime__c <= :endtime And Resource__r.User__c != null AND Resource__r.Recieve_Allocation_Alerts__c = true];
       
         }   
        CustomNotificationType NT   =   [ SELECT Id, CustomNotifTypeName, DeveloperName from CustomNotificationType WHERE DeveloperName = 'ro_Allocation_Upcoming_Alert' LIMIT 1];  
         for(Resource_Allocation__c RA : ALLallocations){
            // Send notifications to be built after winter 21 update    
       		 Messaging.CustomNotification obj = new Messaging.CustomNotification(); 
             obj.setNotificationTypeId(NT.id);
             obj.setTargetId(RA.id);
             obj.setTitle('Upcoming Allocation '+RA.name);
       		 obj.setBody(RA.subject__c);
        	 obj.send(new set<String>{RA.Resource__r.User__c});
      		 }
        }

}