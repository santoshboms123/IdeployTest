/************************************************************************ 
Author : Santosh
Details: 
    Purpose : roReservationTriggerHandler is the Trigger Handler for Reservation__C
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public class roReservationTriggerHandler_Test extends roTestDataFactory {
    
    testMethod static void reservationtest(){
        ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
        
        Reservation_Reason__c RR = new Reservation_Reason__c(name='Test',Active__c = true,Calculate_Utilization__c = true);
        insert RR; 
        
        List<resource__c> testresource = createresourceswithdefaultparent(1);
        testresource[0].user__c = UserInfo.getUserId();
        update  testresource[0];
        
        
            Reservation__c R = new Reservation__c(Reason__c = RR.id, Startdatetime__c = system.now(), EndDateTime__c = system.now().addMinutes(30));
            insert R ;
        	R.Approved__c = true;
        	R.Create_Allocation__c = true;
        	update R ;
        
        Resource_Allocation__c RA = [select id from Resource_Allocation__c where reservation__c = :R.id];
        system.assert(RA != null);
        
        
    }

}