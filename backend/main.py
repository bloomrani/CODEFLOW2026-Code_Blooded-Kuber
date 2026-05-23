from fastapi import FastAPI, UploadFile, File, HTTPException
import pandas as pd
import joblib
import io
import re

app = FastAPI(title="CodeFlow AI Bank Statement Analyzer")

# Load your custom-trained machine learning model
try:
    classifier = joblib.load('bank_transaction_classifier.pkl')
except Exception as e:
    print(f"Error loading model: {e}. Please ensure train_model.py has run successfully.")

def identify_recurring(narration: str) -> bool:
    """
    Helper logic to flag common recurring strings (EMIs, subscriptions, bills)
    to fulfill the recurring payment identification requirement.
    """
    text = str(narration).upper()
    recurring_keywords = ['NETFLIX', 'SPOTIFY', 'EMI', 'LOAN', 'FIBER', 'BILL', 'SUBSCRIBE', 'COURSERA', 'UDEMY']
    return any(keyword in text for keyword in recurring_keywords)

@app.post("/analyze")
async def analyze_statement(file: UploadFile = File(...)):
    # 1. Validate file extension type
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload a standard CSV bank statement.")
        
    contents = await file.read()
    
    try:
        # 2. Read the uploaded raw stream into a pandas DataFrame
        df = pd.read_csv(io.BytesIO(contents))
        
        # Ensure column headers match expected casing
        df.columns = [col.strip().capitalize() for col in df.columns]
        
        if 'Narration' not in df.columns:
            raise HTTPException(status_code=400, detail="Missing required 'Narration' column in statement.")
        
        # Fill missing values to prevent execution crashes
        df['Debit'] = df['Debit'].fillna(0.0).astype(float)
        df['Credit'] = df['Credit'].fillna(0.0).astype(float)
        df['Balance'] = df['Balance'].fillna(0.0).astype(float)
        df['Date'] = df['Date'].fillna("Unknown")

        # 3. Predict Categories using your Custom AI Pipeline
        df['Predicted_Category'] = classifier.predict(df['Narration'])
        
        # 4. Identify Recurring Payments
        df['Is_Recurring'] = df['Narration'].apply(identify_recurring)

        # 5. Compute Financial Aggregations
        total_expense = float(df['Debit'].sum())
        total_income = float(df['Credit'].sum())
        net_savings = total_income - total_expense
        
        # Extract individual expense records to build the pie chart data
        expense_mask = df['Debit'] > 0
        expense_df = df[expense_mask]
        
        category_totals = expense_df.groupby('Predicted_Category')['Debit'].sum().to_dict()
        
        # Find the highest spending domain metric
        highest_spending_category = "None"
        if category_totals:
            highest_spending_category = max(category_totals, key=category_totals.get)

        # 6. Separate recurring payment profiles for UI warning/flags cards
        recurring_df = df[df['Is_Recurring'] == True]
        recurring_list = []
        for _, row in recurring_df.iterrows():
            recurring_list.append({
                "date": str(row['Date']),
                "narration": str(row['Narration']),
                "amount": float(row['Debit']) if row['Debit'] > 0 else float(row['Credit']),
                "category": str(row['Predicted_Category'])
            })

        # 7. Format individual transaction rows to display in the main application feed
        clean_transactions = []
        for _, row in df.iterrows():
            clean_transactions.append({
                "date": str(row['Date']),
                "narration": str(row['Narration']),
                "debit": float(row['Debit']),
                "credit": float(row['Credit']),
                "balance": float(row['Balance']),
                "category": str(row['Predicted_Category']),
                "is_recurring": bool(row['Is_Recurring'])
            })

        # 8. Return structured payload response directly to the Flutter UI pipeline
        return {
            "status": "success",
            "metrics": {
                "total_income": total_income,
                "total_expense": total_expense,
                "net_savings": net_savings,
                "highest_spending_category": highest_spending_category
            },
            "category_breakdown": category_totals,
            "recurring_payments": recurring_list,
            "transactions": clean_transactions
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal data processing error: {str(e)}")