public with sharing class OpportunityLineItemController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getOpportunityPricebookEntries(Id opportunityId, Id pricebookId) {
        
        if (opportunityId == null || pricebookId == null) {
            throw new AuraHandledException('必須のIDが不足しています。');
        }

        // グローバル値セットの選択リストを取得
        Map<String, String> category1Map = new Map<String, String>();
        Map<String, String> category2Map = new Map<String, String>();

        Schema.DescribeFieldResult category1Field = PricebookEntryMaster__c.Category1__c.getDescribe();
        for (Schema.PicklistEntry entry : category1Field.getPicklistValues()) {
            category1Map.put(entry.getValue(), entry.getLabel());
        }

        Schema.DescribeFieldResult category2Field = PricebookEntryMaster__c.Category2__c.getDescribe();
        for (Schema.PicklistEntry entry : category2Field.getPicklistValues()) {
            category2Map.put(entry.getValue(), entry.getLabel());
        }

        // 価格表エントリマスタを取得
        List<PricebookEntryMaster__c> pricebookEntries = [
            SELECT Id, Pricebook__c, Product2__c, Product2__r.Name, ProductCode__c, IsActive__c, CostPrice__c, UnitPrice__c, Category1__c, Category2__c
            FROM PricebookEntryMaster__c 
            WHERE Pricebook__c = :pricebookId
            AND Product2__c NOT IN (
            	SELECT Product2__c
                FROM OpportunityLineItemMaster__c 
                WHERE Opportunity__c = :opportunityId
                )
		];

        // API参照名を表示ラベルに変換
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (PricebookEntryMaster__c entry : pricebookEntries) {
            Map<String, Object> record = new Map<String, Object>();
            record.put('Id', entry.Id);
            record.put('Pricebook__c', entry.Pricebook__c);
            record.put('Product2__c', entry.Product2__c);
            record.put('ProductName', entry.Product2__r.Name);
            record.put('ProductCode__c', entry.ProductCode__c);
            record.put('IsActive__c', entry.IsActive__c);
            record.put('CostPrice__c', entry.CostPrice__c);
            record.put('UnitPrice__c', entry.UnitPrice__c);
            record.put('Category1__c', category1Map.get(entry.Category1__c));
            record.put('Category2__c', category2Map.get(entry.Category2__c));

            result.add(record);
        }
        
        return result;
    }

    // 商談、価格表を取得
    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getOpportunityHelper(Id opportunityId) {

        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId が NULL です');
        }

        Opportunity opp = [SELECT Pricebook__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opp == null || opp.Pricebook__c == null) {
            throw new AuraHandledException('商談に価格表が設定されていません。');
        }

        return new Map<String, Id>{
            'pricebookId' => opp.Pricebook__c
        };
    }   

    // 商品分類の値を取得
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getCategoryOptions() {
        Map<String, List<String>> result = new Map<String, List<String>>();
    
        List<String> category1List = new List<String>();
        Schema.DescribeFieldResult category1Field = PricebookEntryMaster__c.Category1__c.getDescribe();
        for (Schema.PicklistEntry entry : category1Field.getPicklistValues()) {
            category1List.add(entry.getLabel());
        }
    
        List<String> category2List = new List<String>();
        Schema.DescribeFieldResult category2Field = PricebookEntryMaster__c.Category2__c.getDescribe();
        for (Schema.PicklistEntry entry : category2Field.getPicklistValues()) {
            category2List.add(entry.getLabel());
        }
    
        result.put('category1', category1List);
        result.put('category2', category2List);
        return result;
    }
    
    @AuraEnabled
    public static List<OpportunityLineItemMaster__c> createLineItems(List<OpportunityLineItemMaster__c> finalData) {
        if (finalData == null || finalData.isEmpty()) {
            throw new AuraHandledException('追加する商品がありません。');
        }
        
        try {
            insert finalData;
        } catch (DmlException e) {
            throw new AuraHandledException('商談商品の作成中にエラーが発生しました。' + e.getMessage());
        }

        return finalData;
    }
}