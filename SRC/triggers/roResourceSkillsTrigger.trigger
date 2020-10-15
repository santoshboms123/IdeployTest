trigger roResourceSkillsTrigger on Resource_Skills__c (Before insert,After insert) {
    roTriggerDispatcher.run(roTriggerDispatcher.handlerClass.roResourceSkillsTriggerHandler);
}