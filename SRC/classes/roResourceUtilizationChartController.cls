/************************************************************************ 
Author : Ramtej
Details: 
    Purpose : roResourceUtilizationChartController - Programmed to show weekly utilization on Resource Detail interface. 
    Intial release date : October 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceUtilizationChartController {

    public static Id dailyUtilizationRecTypeId  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Daily Utilization').getRecordTypeId();

    @AuraEnabled
    public static chartJson getChartData(List<Id> resourceIdList, Date selectedDate){
        chartJson chartDataRet = new chartJson();
        try{
            system.debug('resourceIdList '+resourceIdList+' selectedDate '+selectedDate);
            if(selectedDate == null){
                selectedDate = system.today();
            }
            chartDataRet.dataLabel = new Set<String>();
            Date weekStartDate = selectedDate.toStartOfWeek();
            Date weekEndDate = weekStartDate.addDays(6);
            Map<Id, Map<Date, Decimal>> existingResourceDateMapping = new Map<Id, Map<Date, Decimal>>();
            List<dataSet> dataSetList = new List<dataSet>();
            List<Resource__c> AllResources = New List<Resource__c>();
           
            if(roSecurityHandler.checkField(new String[] {'First_Name__c','Last_Name__c','Active__c'},'Resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
              roSecurityHandler.checkField(new String[] {'Utilization_Date__c','Utilization__c'},'Resource_Utilization__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
              roSecurityHandler.checkObject('Resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
              roSecurityHandler.checkObject('Resource_Utilization__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
				AllResources = [SELECT Id, First_Name__c, Last_Name__c, (SELECT Id, Utilization_Date__c, 
            Utilization__c FROM Resource_Utilization__r WHERE RecordTypeId = :dailyUtilizationRecTypeId AND Utilization_Date__c != null 
            AND Utilization_Date__c >= :weekStartDate AND Utilization_Date__c <= :weekEndDate ORDER BY Utilization_Date__c) 
            FROM Resource__c WHERE Id IN :resourceIdList AND Active__c = true];                
            }
            

            for(Resource__c res : AllResources){
                List<Decimal> resUtilizationVals = new List<Decimal>();
                dataSet ds = new dataSet();
                for(integer i = 0; i <= 6; i++){
                    boolean dateFound = false;
                    for(Resource_Utilization__c resEff :res.Resource_Utilization__r){
                        if(string.valueOf(weekStartDate.addDays(i)) == string.valueOf(resEff.Utilization_Date__c)){
                            resUtilizationVals.add(resEff.Utilization__c);
                            dateFound = true;
                        }
                    }
                    if(!dateFound){
                        resUtilizationVals.add(0);
                    }
                    chartDataRet.dataLabel.add(string.valueOf(weekStartDate.addDays(i)));
                }
                ds.dataSetName = res.First_Name__c+' '+res.Last_Name__c;
                ds.dataValueList = resUtilizationVals;
                dataSetList.add(ds);

            }

            chartDataRet.dataSetList = dataSetList;
            system.debug('chartDataRet '+JSON.serialize(chartDataRet));
            return chartDataRet;
        }
        catch(exception ex){
            roResourceOptimizerUtility.logExceptionMessage(ex.getMessage(), 'get chart data ', ex.getStackTraceString());
            return null;
        }
    }

    public class chartJson{
        @AuraEnabled public Set<String> dataLabel {get; set;}
        @AuraEnabled public List<dataSet> dataSetList {get; set;}
    }

    public class dataSet{
        @AuraEnabled public string dataSetName {get; set;}
        @AuraEnabled public List<Decimal> dataValueList {get; set;}
    }
}