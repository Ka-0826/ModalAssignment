public class PricebookEntryController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPricebookEntries(Id pricebookId) {
        System.debug('Apex メソッドが呼ばれました。pricebookId: ' + pricebookId);
        
        // recordId が null の場合はエラーを返す
        if (pricebookId == null) {
            throw new AuraHandledException('pricebookId が null です');
        }

        // グローバル値セットの選択リストを取得
        Map<String, String> category1Map = new Map<String, String>();
        Map<String, String> category2Map = new Map<String, String>();

        Schema.DescribeFieldResult category1Field = Product2.Category1__c.getDescribe();
        for (Schema.PicklistEntry entry : category1Field.getPicklistValues()) {
            category1Map.put(entry.getValue(), entry.getLabel());
        }

        Schema.DescribeFieldResult category2Field = Product2.Category2__c.getDescribe();
        for (Schema.PicklistEntry entry : category2Field.getPicklistValues()) {
            category2Map.put(entry.getValue(), entry.getLabel());
        }
        
        // 商品を取得
        List<Product2> Products = [
            SELECT Id, Name, ProductCode, IsActive, Category1__c, Category2__c
            FROM Product2 
            WHERE IsActive = true
            AND Id NOT IN (
                // すでに作成されている価格表エントリマスタを除外
            	SELECT Product2__c
                FROM PricebookEntryMaster__c 
                WHERE Pricebook__c = :pricebookId
                )
		];

        // API参照名を表示ラベルに変換
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Product2 entry : products) {
            Map<String, Object> record = new Map<String, Object>();
            record.put('Id', entry.Id);
            record.put('Name', entry.Name);
            record.put('ProductCode', entry.ProductCode);
            record.put('IsActive', entry.IsActive);
            record.put('Category1__c', category1Map.get(entry.Category1__c));
            record.put('Category2__c', category2Map.get(entry.Category2__c));

            result.add(record);
        }
        
        System.debug('取得した商品: ' + result);
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getCategoryOptions() {
        Map<String, List<String>> result = new Map<String, List<String>>();
    
        // 商品分類1の値を取得
        List<String> category1List = new List<String>();
        Schema.DescribeFieldResult category1Field = Product2.Category1__c.getDescribe();
        for (Schema.PicklistEntry entry : category1Field.getPicklistValues()) {
            category1List.add(entry.getLabel()); 
        }
    
        // 商品分類2の値を取得
        List<String> category2List = new List<String>();
        Schema.DescribeFieldResult category2Field = Product2.Category2__c.getDescribe();
        for (Schema.PicklistEntry entry : category2Field.getPicklistValues()) {
            category2List.add(entry.getLabel()); 
        }
    
        result.put('category1', category1List);
        result.put('category2', category2List);
        return result;
    }
    
    @AuraEnabled
    public static List<PricebookEntryMaster__c> createItems(List<PricebookEntryMaster__c > finalData) {
        if (finalData == null || finalData.isEmpty()) {
            throw new AuraHandledException('追加する商品がありません。');
        }
        
        try {
            // DML 処理を部分成功可能にする
            Database.SaveResult[] results = Database.insert(finalData, false);
            List<PricebookEntryMaster__c> successfulRecords = new List<PricebookEntryMaster__c>();

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
            throw new AuraHandledException('価格表エントリの作成中にエラーが発生しました: ' + e.getMessage());
        }
    }
} 