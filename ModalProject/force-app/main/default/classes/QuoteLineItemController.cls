public with sharing class QuoteLineItemController {

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntryMaster__c> getQuotePricebookEntries(Id quoteId) {
        System.debug('Apex メソッドが呼ばれました。quoteId: ' + quoteId);
        
        // recordId が null の場合はエラーを返す
        if (quoteId == null) {
            throw new AuraHandledException('quoteId が null です');
        }
        
        // 見積に紐づく商談を取得
        Quote__c quo = [SELECT Opportunity__c FROM Quote__c WHERE Id = :quoteId LIMIT 1];

        if (quo == null || quo.Opportunity__c == null) {
            throw new AuraHandledException('見積が設定されていません。');
        } 
        
        Id opportunityId = quo.Opportunity__c;

        // 商談に紐づく価格表マスタを取得
        Opportunity opp = [SELECT Pricebook__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        if (opp == null || opp.Pricebook__c == null) {
            throw new AuraHandledException('商談に価格表が設定されていません。');
        }
        
        Id pricebookId = opp.Pricebook__c;

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
                // すでに追加されている見積品目の商品を除外
                SELECT Product2__c
                FROM QuoteLineItemMaster__c 
                WHERE Quote__c = :quoteId
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
            
            // API参照名を表示ラベルに変換
            record.put('Category1__c', category1Map.get(entry.Category1__c));
            record.put('Category2__c', category2Map.get(entry.Category2__c));

            result.add(record);
        }
        
        System.debug('取得した価格表エントリ: ' + pricebookEntries);
        return pricebookEntries;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getCategoryOptions() {
        Map<String, List<String>> result = new Map<String, List<String>>();
    
        // カテゴリ1のユニーク値を取得
        List<String> category1List = new List<String>();
        Schema.DescribeFieldResult category1Field = PricebookEntryMaster__c.Category1__c.getDescribe();
        for (Schema.PicklistEntry entry : category1Field.getPicklistValues()) {
            category1List.add(entry.getLabel()); // 画面表示用
        }
    
        // カテゴリ2のユニーク値を取得
        List<String> category2List = new List<String>();
        Schema.DescribeFieldResult category2Field = PricebookEntryMaster__c.Category2__c.getDescribe();
        for (Schema.PicklistEntry entry : category2Field.getPicklistValues()) {
            category2List.add(entry.getLabel()); // 画面表示用
        }
    
        result.put('category1', category1List);
        result.put('category2', category2List);
        return result;
    }
    
    @AuraEnabled
    public static List<QuoteLineItemMaster__c> createLineItems(List<QuoteLineItemMaster__c> finalData) {
        if (finalData == null || finalData.isEmpty()) {
            throw new AuraHandledException('追加する商品がありません。');
        }
        
        try {
            // DML 処理を部分成功可能にする
            Database.SaveResult[] results = Database.insert(finalData, false);
            List<QuoteLineItemMaster__c> successfulRecords = new List<QuoteLineItemMaster__c>();

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successfulRecords.add(finalData[i]);
                } else {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('レコード挿入エラー: ' + err.getMessage());
                    }
                }
            }
        
            return successfulRecords;
        } catch (Exception e) {
            throw new AuraHandledException('見積品目の作成中にエラーが発生しました: ' + e.getMessage());
        }
    }
}