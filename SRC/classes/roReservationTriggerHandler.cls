/************************************************************************ 
Author : Santosh
Details: 
  Purpose : roReservationTriggerHandler is the Trigger Handler for Reservation__C
  Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roReservationTriggerHandler extends roITriggerHandler{
  public override void beforeInsert(List<Sobject> newList){
    roReservationTriggerAction.updateresources((List<Reservation__c>) newList);
  }

  public override void afterUpdate(Map<Id, Sobject> newMap, Map<Id, Sobject> oldMap){
    roReservationTriggerAction.createorupdateresourceallocation((List<Reservation__c>) newMap.values(), (Map<Id, Reservation__c>) oldMap);
  }
}