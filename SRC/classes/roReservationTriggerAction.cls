public with sharing class roReservationTriggerAction {
    public static void updateresources( list<Reservation__c> newreservations){
        if(roSecurityHandler.checkField(new String[] {'active__c','user__c'}, 'resource__c', roSecurityHandler.permissionLevel.ISACCESSIBLE)){
            List<resource__c> currentuserresource =  [select id from resource__c where active__c = true AND user__c = :UserInfo.getUserId() limit 1];
            if(currentuserresource != null && 
            roSecurityHandler.checkField(new String[] {'Resource__c'}, 'Reservation__c', roSecurityHandler.permissionLevel.ISUPDATABLE)){
                for(Reservation__c R : newreservations){
                    if(R.Resource__c == null){
                        if(currentuserresource.size()>0){
                            R.Resource__c =  currentuserresource[0].Id ;   
                        }
                    }
                }
            }
        }
    }
      
    public static void createorupdateresourceallocation (list<Reservation__c> newreservations, map<Id,Reservation__c> oldreservationsmap){
        List<resource_allocation__c> newallocations = new List<resource_allocation__c>(); 
        for(Reservation__c R : newreservations){
            if(R.Approved__c == true && R.Create_Allocation__c == true && oldreservationsmap.get(R.id).Create_Allocation__c == false){
            resource_allocation__c RA = new resource_allocation__c();
                RA.resource__c = R.Resource__c ;
                RA.Reservation__c = R.id ;
                RA.Allocated_Start_DateTime__c = R.Startdatetime__c ;
                RA.Allocated_End_Datetime__c = R.EndDateTime__c ;
                // RA.Calculate_Utilization__c = R.Reason__r.Consider_Efficiency__c ;
                RA.Description__c = R.Description__c ;
                RA.Status__c = 'Completed';
                newallocations.add(RA);
            }
        }
        if(roSecurityHandler.checkObject('resource_allocation__c', roSecurityHandler.permissionLevel.ISCREATABLE)){
            Database.insert(newallocations,false); 
        }
    }
}