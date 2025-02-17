import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions'; 
import getOpportunityPricebookEntries from '@salesforce/apex/OpportunityLineItemController.getOpportunityPricebookEntries';
import getCategoryOptions from '@salesforce/apex/OpportunityLineItemController.getCategoryOptions';
import createLineItems from '@salesforce/apex/OpportunityLineItemController.createLineItems';
import { getRecord } from 'lightning/uiRecordApi';

const OPPORTUNITY_FIELDS = ['Opportunity.Id'];

export default class createOpportunityLineItem extends LightningElement {

    // 商品選択画面のヘッダー行
    columnsDatatable = [
        { label: '商品名', fieldName: 'Name', type: 'text' },
        { label: '商品コード', fieldName: 'ProductCode', type: 'text' },
        { label: '有効', fieldName: 'IsActive', type: 'boolean' },
        { label: '原価', fieldName: 'CostPrice', type: 'currency' },
        { label: '販売価格', fieldName: 'UnitPrice', type: 'currency' },
        { label: '商品分類1', fieldName: 'Category1', type: 'text' },
        { label: '商品分類2', fieldName: 'Category2', type: 'text' }
    ];

    // 商品編集画面のヘッダー行
    columnsAdd = [
        { label: '商品名', fieldName: 'Name', type: 'text', editable: false },
        { label: '数量', fieldName: 'Quantity', type: 'number', editable: true,
            typeAttributes: { minimumFractionDigits: '2' } 
        },
        { label: '原価', fieldName: 'CostPrice', type: 'currency', editable: false },
        { label: '販売価格', fieldName: 'UnitPrice', type: 'currency', editable: true },
        { label: '割引（パーセント）', fieldName: 'Discount', type: 'number', editable: true, 
            typeAttributes: { step: '0.01' } },
        {
            type: 'button-icon',
            typeAttributes: {
            iconName: 'utility:delete',
            name: 'delete',
            rowId: { fieldName: 'id' },
            alternativeText: '削除',
            size: 'small',
            variant: 'bare',
            }
        }
    ];

    @track gridData = [];         // 商品選択画面のデータ行
    @track options1 = [];         // 選択リスト：商品分類1で選択したデータ
    @track options2 = [];         // 選択リスト：商品分類2で選択したデータ
    @track selectedRows = [];     // 選択された行のリストを保持
    @track secondTableData = [];  // 商品編集画面に渡すデータ行
    @track selectedIds = '';      // 選択されたデータId
    @track draftValues = [];      // インライン編集の値を保持
    @track updatedValues = [];    // 編集された後のデータ行
    @track deletedProduct = [];   // 削除対象のデータ行

    opportunityId;                // 現在開いているレコードIdの格納先
    data = [];                    // 取得した商品リスト
    error;

    selectedOption1 = '';         // 選択リスト：商品分類1
    selectedOption2 = '';         // 選択リスト：商品分類2
    isFirstOpen = true;           // 商品選択画面
    isSecondOpen = false;         // 商品編集画面
    hideCheckboxColumn1 = false;  // 商品選択画面のチェックボックス
    hideCheckboxColumn2 = true;   // 商品編集画面のチェックボックス
    
    @api recordId;                // 現在開いているレコードId
    
    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            this.opportunityId = data.fields.Id.value;
            
            if (this.opportunityId) {
                this.loadProducts();
                this.loadCategoryOptions();  // 商品分類をロード
            } else {
                console.error('opportunityId が設定されていません');
            }
        } else if (error) {
            console.log('wiredOpportunity error:', error);
            this.showToast('エラー', 'データの取得に失敗しました。', 'error');
        }
    }

    //  商品データの取得
    async loadProducts() {
        try {
            const data = await getOpportunityPricebookEntries({ opportunityId: this.opportunityId });

            const records = Array.isArray(data) ? data : data.records;
                if (!(data instanceof Array)) {
                    console.error('取得データが配列ではありません:', JSON.stringify(data, null, 2));
                    throw new Error('取得データが配列ではありません');
                }

                this.gridData = data.map(item => ({
                    Id: item.Id,
                    ProductId: item.Product2__c,
                    Name: item.Product2__r ? item.Product2__r.Name : '',
                    ProductCode: item.ProductCode__c,
                    IsActive: item.IsActive__c,
                    CostPrice: item.CostPrice__c,
                    UnitPrice: item.UnitPrice__c,
                    Category1: item.Category1__c,
                    Category2: item.Category2__c
                }));
        } catch (error) {
            console.error('データ取得エラー:', error);
            this.showToast('エラー', 'データの取得に失敗しました。', 'error');
        }
    };

    //  フィルター（商品分類）の取得
    async loadCategoryOptions() {
        try {
            const data = await getCategoryOptions();
            if (data) {
                this.options1 = data.category1.map(value => ({ label: value, value }));
                this.options2 = data.category2.map(value => ({ label: value, value }));
            }
        } catch (error) {
            console.error('商品分類の取得エラー:', error);
        }
    }

    // 商品分類1（combobox1）の選択変更
    handleChange1(event) {
        this.selectedOption1 = event.detail.value;
    }

    // 商品分類2（combobox2）の選択変更
    handleChange2(event) {
        this.selectedOption2 = event.detail.value;
    }

    // クリアボタンの処理
    handleClear() {
        console.log('クリアボタンがクリックされました');
        this.selectedOption1 = '';
        this.selectedOption2 = '';
    }

    // フィルターを変更しても選択状態を保持
    get filteredData() {
        const filtered = this.gridData.filter(
            item =>
                (this.selectedOption1 ? item.Category1 === this.selectedOption1 : true) &&
                (this.selectedOption2 ? item.Category2 === this.selectedOption2 : true)
        );
        // 選択状態を保持
        this.updateSelectedRows(filtered);

        return filtered;
    }

    // 選択された行を更新する処理
    updateSelectedRows(filtered) {
        if (!this.selectedRows) {
            this.selectedRows = [];
        }

        // 選択された行の Id を取得
        const selectedIds = this.selectedRows.map(row => row.Id);

        // フィルター後に表示される行の Id を取得
        const filteredIds = filtered.map(item => item.Id);

        // フィルター後に表示される行に関係なく、選択された行がそのまま維持される
        // フィルター後の選択行をフィルタリングせず、選択状態の行が選ばれている状態にする
        this.selectedRows = this.selectedRows.map(row => {
            if (selectedIds.includes(row.Id)) {
                // 選択されている行がフィルター後に表示される場合、その行を選択状態に保持
                return row;
            }
            // フィルター後に選択されるべき行（新しい選択対象）を追加
            if (filteredIds.includes(row.Id)) {
                return row;
            }
            return null;  // フィルター後に表示されない行は除外
        }).filter(row => row !== null);

        // 既に選択された行の ID とフィルター後に新たに選択された行を統合
        const newlySelectedRows = filtered.filter(item => selectedIds.includes(item.Id));

        // 新たに選択された行を選択状態にする
        this.selectedRows = [...this.selectedRows, ...newlySelectedRows];

        // 重複行の削除（Idで一意にする）
        this.selectedRows = this.selectedRows.filter((row, index, self) =>
            index === self.findIndex(r => r.Id === row.Id)
        );
    }

    // 選択されたデータを更新
    handleRowSelection(event) {
        if (!this.selectedRows) {
            this.selectedRows = [];
        }
        
        const selectedRows = event.detail.selectedRows;
        
        // 重複を避けて統合する
        const updatedSelectedRows = [...this.selectedRows, ...selectedRows];
        
        // 重複を削除
        this.selectedRows = updatedSelectedRows.filter((row, index, self) =>
            index === self.findIndex(r => r.Id === row.Id) // Idのキー名を確認
        );
    }

    // 次へボタンの処理
    handleNext() {
        if (this.selectedRows.length === 0) {
            this.showToast('警告', '商品を選択してください。', 'warning');
            return;
        }
        // 選択されたデータをコピー
        this.secondTableData = [...this.selectedRows];

        // 次の 商品編集画面 を表示
        this.isFirstOpen = false;
        this.isSecondOpen = true; 
        this.hideCheckboxColumn1 = true;
        this.hideCheckboxColumn2 = true;
    }

    // 削除ボタンの処理
    deleteRowAction(event) {
        const actionName = event.detail.action.name;
        const rowId = event.detail.row.Id;

        if (actionName === 'delete') {
            this.secondTableData = this.secondTableData.filter(item => item.Id !== rowId);
            this.showToast('成功', '商品が削除されました。', 'success');
        }
    }

    // インライン編集の処理
    handleCellChange(event) {
        const updatedValues = event.detail.draftValues;
    
        updatedValues.forEach(update => {
            let row = this.secondTableData.find(item => item.Id === update.Id);
            if (row) {
                Object.keys(update).forEach(key => {
                    if (key === 'Discount') {
                        // 数値変換
                        row[key] = update[key] != null && !isNaN(Number(update[key])) ? Number(update[key]) : 0;
                    } else if (key === 'Quantity' || key === 'CostPrice' || key === 'UnitPrice') {
                        // 数値変換（整数または小数）
                        row[key] = update[key] != null && !isNaN(Number(update[key])) ? Number(update[key]) : 0;
                    } else {
                        row[key] = update[key];  // その他の値はそのまま
                    }
                });
            }
        });
    
        // 変更後に draftValues をクリア
        this.draftValues = [];
    }

    // レコード作成の処理
    handleSave(event) {
        // データが存在しない場合、エラーを表示
        if (!this.secondTableData || this.secondTableData.length === 0) {
            this.showToast('警告', '商品を選択してください。', 'warning');
            return; // 処理を中断
        }

        // データが存在する場合、保存処理を実行
        const finalData = this.secondTableData.map(item => ({
            Opportunity__c: this.recordId,
            Product2__c: item.ProductId,
            Name: '商談商品 ' + item.Name,
            Quantity__c: item.Quantity != null && item.Quantity !== '' ? item.Quantity : 1,
            CostPrice__c: item.CostPrice,
            UnitPrice__c: item.UnitPrice,
            Discount__c: item.Discount ? item.Discount : null,
        }));

        console.log('保存データ:', JSON.stringify(finalData, null, 2));

        createLineItems({ finalData })
            .then(() => {
                this.showToast('成功', '商談商品が作成されました。', 'success');

                // モーダルを閉じる
                this.dispatchEvent(new CloseActionScreenEvent()); 

                // 編集済みの状態を確定
                this.draftValues = [];
            })
            .catch(error => {
                console.error('保存エラー:', error);
                this.showToast('エラー', '商談商品の作成に失敗しました。', 'error');
            });
    }

    // クローズボタンの処理
    closeModal(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
      }

    // メッセージの処理
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}
