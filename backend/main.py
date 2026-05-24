import re
from fastapi import FastAPI, UploadFile, File, HTTPException
import pandas as pd
import joblib
import io
import random
from fastapi.middleware.cors import CORSMiddleware
from pypdf import PdfReader

app = FastAPI(title="CodeFlow AI Double-Model Analyzer")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows any origin (including localhost)
    allow_credentials=True,
    allow_methods=["*"],  # Allows POST, GET, etc.
    allow_headers=["*"],  # Allows your custom ngrok headers
)

# --- Load BOTH of your custom-trained offline AI models ---
classifier = joblib.load('bank_transaction_classifier.pkl')
recommender_brain = joblib.load('custom_recommender_model.pkl')

def extract_df_from_pdf(pdf_bytes: bytes) -> pd.DataFrame:
    """Parses text-wrapped, multi-line Indian bank PDF streams into data rows."""
    reader = PdfReader(io.BytesIO(pdf_bytes))
    all_text = ""
    
    for page in reader.pages:
        text_content = page.extract_text()
        if text_content:
            all_text += text_content + "\n"
        
    parsed_rows = []
    
    # Stateful buffers to track our multi-line assembly line
    current_date_fragments = []
    current_narration_fragments = []

    # Regex patterns to detect states
    date_part_pattern = re.compile(r'^(\d{2}-|[A-Za-z]{3}-|\d{2,4})') # Catches "01-", "Sep-", "2023"
    full_date_validation = re.compile(r'^\d{2}-[A-Za-z0-9]{3}-\d{2,4}$') # Verifies "01-Sep-2023"

    for line in all_text.split('\n'):
        cleaned_line = line.strip()
        if not cleaned_line:
            continue
            
        # Try to parse numeric column block from the right side
        parts = cleaned_line.rsplit(maxsplit=3)
        
        # STATE 1: We found the numeric tail end of a transaction!
        if len(parts) >= 3 and all(p.replace('.', '', 1).replace('-', '').isdigit() for p in parts[-3:]):
            try:
                val3 = parts[-1].replace(',', '')  # Balance
                val2 = parts[-2].replace(',', '')  # Credit
                val1 = parts[-3].replace(',', '')  # Debit
                
                # Grab any stray narration sitting on this number line
                if len(parts) > 3:
                    current_narration_fragments.append(cleaned_line.rsplit(maxsplit=3)[0].strip())
                
                # Assemble our buffered components
                assembled_date = "".join(current_date_fragments).strip()
                assembled_narration = " ".join(current_narration_fragments).strip()
                
                # Fallback if the date buffer wasn't filled correctly
                if not assembled_date or not full_date_validation.match(assembled_date):
                    assembled_date = "Unknown"
                    
                debit_val = float(val1) if val1 != '0' else 0.0
                credit_val = float(val2) if val2 != '0' else 0.0
                balance_val = float(val3)
                
                parsed_rows.append({
                    "Date": assembled_date,
                    "Narration": assembled_narration if assembled_narration else "Bank Transaction",
                    "Debit": debit_val,
                    "Credit": credit_val,
                    "Balance": balance_val
                })
                
                # 🎉 Clear the buffers immediately for the next transaction row block
                current_date_fragments = []
                current_narration_fragments = []
                continue
                
            except ValueError:
                pass # Fall through to string processing if number casting hit an edge case
                
        # STATE 2: Accumulate Date fragments ("01-", "Sep-", "2023")
        if date_part_pattern.match(cleaned_line) and len(cleaned_line) <= 5:
            current_date_fragments.append(cleaned_line)
            
        # STATE 3: It's text, it's not a short date piece, and it's not numbers -> It's Narration!
        elif not cleaned_line.startswith("Statement") and not cleaned_line.startswith("Account") and not cleaned_line.startswith("Period") and "Date Narration" not in cleaned_line:
            current_narration_fragments.append(cleaned_line)

    if not parsed_rows:
        raise ValueError("Could not parse transaction rows from this fractured PDF layout.")
        
    return pd.DataFrame(parsed_rows)
def generate_ai_recommendation(highest_spending_category: str, net_savings: float, max_words=20) -> str:
    chains = recommender_brain.get("chains", {})
    starters = recommender_brain.get("starters", {})

    def generate_sentence(target_domain):
        category_chain = chains.get(target_domain)
        category_starters = starters.get(target_domain)

        if not category_chain or not category_starters:
            return ""

        current_state = random.choice(category_starters)
        generated_sentence = [current_state[0], current_state[1]]

        for _ in range(max_words):
            possible_next_words = category_chain.get(current_state, [])
            if not possible_next_words:
                break
            next_word = random.choice(possible_next_words)
            generated_sentence.append(next_word)
            current_state = (current_state[1], next_word)

        raw_text = " ".join(generated_sentence).strip()
        return raw_text if raw_text.endswith('.') else raw_text + '.'

    # 1. Get advice explicitly for the highest category
    target_category = str(highest_spending_category).capitalize()
    spending_advice = generate_sentence(target_category)
    
    # 2. Get forward-looking advice if they made a profit
    investing_advice = ""
    if net_savings > 0:
        investing_advice = generate_sentence("Investing")

    # 3. Clean and Compose the Final Insight (Empathetic Engine)
    if target_category == "Healthcare":
        if net_savings <= 0:
            final_payload = (
                f"Sudden medical and health priorities created an exceptional deficit of ₹{abs(net_savings):,.2f} this month. "
                f"Recovery Insight: {spending_advice} "
                f"Prioritizing your physical recovery takes precedence, while building back an emergency cash buffer can stabilize your upcoming cycles."
            )
        else:
            final_payload = (
                f"Your statement reflects significant medical outlays this cycle. "
                f"Recommendation: {spending_advice} "
                f"Since you still maintained a net surplus of ₹{net_savings:,.2f}, your baseline financial framework remains highly resilient."
            )
    elif spending_advice and investing_advice:
        final_payload = (
            f"Your primary expenditure this cycle was concentrated in {target_category}. "
            f"Strategy: {spending_advice} "
            f"Since you secured a net surplus of ₹{net_savings:,.2f}, consider your next move: {investing_advice}"
        )
    elif spending_advice and net_savings <= 0:
        final_payload = (
            f"Heavy activity in {target_category} led to a financial deficit this cycle. "
            f"Correction Strategy: {spending_advice} "
            f"Reducing outlays here is critical to restoring your capital baseline."
        )
    else:
        final_payload = f"Track your {target_category} spending closely to optimize your net savings."

    # Clean up any weird spacing
    return final_payload.replace('  ', ' ').strip()


@app.post("/analyze")
async def analyze_statement(file: UploadFile = File(...)):
    try:
        # 🌟 THE WEB SAFEGUARD: Strip spaces and lowercase the extension check
        if not file.filename:
            raise ValueError("No file name detected from the upload stream.")
            
        filename_lower = file.filename.strip().lower()
        print(f"📥 Processing incoming file on backend: {file.filename}")
        
        contents = await file.read()
        
        # 🌟 MULTI-FORMAT FORK: Process CSV or PDF safely
        if filename_lower.endswith('.csv'):
            df = pd.read_csv(io.BytesIO(contents))
            # Standardize initial column strings to Title Case
            df.columns = [col.strip().capitalize() for col in df.columns]
            
            # Map varying bank headers to Kuber's internal standard
            column_aliases = {
                'Description': 'Narration', 'Particulars': 'Narration',
                'Remarks': 'Narration', 'Transaction remarks': 'Narration',
                'Withdrawals': 'Debit', 'Withdrawal': 'Debit',
                'Deposits': 'Credit', 'Deposit': 'Credit'
            }
            df.rename(columns=column_aliases, inplace=True)
            
        elif filename_lower.endswith('.pdf'):
            # Route to your new PDF parsing logic
            df = extract_df_from_pdf(contents)
            
        else:
            # Drop clean structure without triggering unhandled 500 crashes
            return {
                "status": "error",
                "message": f"Unsupported format. Received: '{file.filename.split('.')[-1]}'. Please use CSV or PDF."
            }
            
        # 🚨 THE CRITICAL FIX: Instantly convert any empty cells to 0 so Pandas math doesn't break
        df = df.fillna(0)
        
        # Model 1: Predict transaction categories
        df['Predicted_Category'] = classifier.predict(df['Narration'])
        
        def keyword_override(row):
            # 🌟 FIX 1: If it's an incoming credit (like Salary), instantly categorize it as Income!
            if float(row.get('Credit', 0)) > 0:
                return 'Income'
                
            narration = str(row['Narration']).upper()
            
            if any(k in narration for k in ['ZOMATO', 'SWIGGY', 'RESTAURANT', 'DINNER', 'FOOD']):
                return 'Food'
            if any(k in narration for k in ['AMAZON', 'MYNTRA', 'FLIPKART', 'ZUDIO', 'SHOPPING', 'APPARELS']):
                return 'Shopping'
            if any(k in narration for k in ['APOLLO', 'PHARMACY', 'PHARMEASY', 'MEDICINES', 'HOSPITAL', 'CLINIC', '1MG', 'PRACTO', 'DIAGNOSTICS', 'BLOOD_TEST', 'MEDPLUS']):
                return 'Healthcare'
            if any(k in narration for k in ['NETFLIX', 'SPOTIFY', 'BOOKMYSHOW', 'CONCERT', 'MOVIES', 'CINEMAS', 'MAKEMYTRIP', 'FLIGHT']):
                return 'Entertainment'
            if any(k in narration for k in ['RENT', 'MAINTENANCE', 'HOUSING', 'SOCIETY']):
                return 'Housing'
            if any(k in narration for k in ['BESCOM', 'ELECTRICITY', 'FIBER', 'JIO', 'AIRTEL', 'GAS', 'INDANE', 'WATER']):
                return 'Utilities'
                
            # If no obvious keywords match, trust the trained machine learning model
            return row['Predicted_Category']
            
        df['Predicted_Category'] = df.apply(keyword_override, axis=1)
        
        # Financial math for metrics
        total_expense = float(df['Debit'].sum())
        total_income = float(df['Credit'].sum())
        
        # Calculate category totals safely
        debit_df = df[df['Debit'] > 0]
        if not debit_df.empty:
            category_totals = debit_df.groupby('Predicted_Category')['Debit'].sum().to_dict()
            highest_category = max(category_totals, key=category_totals.get)
        else:
            category_totals = {}
            highest_category = "Other"

        # Model 2: Generate text using your trained generative recommender model
        custom_ai_text = generate_ai_recommendation(highest_category, total_income - total_expense)

        # 🚨 THE JSON FIX: Ensure absolutely no 'NaN' floats slip through the loop
        clean_transactions = []
        for _, row in df.iterrows():
            clean_transactions.append({
                "date": str(row.get('Date', 'Unknown')),
                "narration": str(row.get('Narration', 'Unknown')),
                "debit": 0.0 if pd.isna(row.get('Debit')) else float(row.get('Debit')),
                "credit": 0.0 if pd.isna(row.get('Credit')) else float(row.get('Credit')),
                "balance": 0.0 if pd.isna(row.get('Balance')) else float(row.get('Balance')),
                "category": str(row.get('Predicted_Category', 'Other'))
            })

        return {
            "status": "success",
            "metrics": {
                "total_income": total_income,
                "total_expense": total_expense,
                "net_savings": total_income - total_expense,
                "highest_spending_category": highest_category
            },
            "category_breakdown": {k: float(v) for k, v in category_totals.items()},
            "transactions": clean_transactions,
            "ai_recommendation": custom_ai_text
        }
        
    # 🌟 NEW: Catches explicit validation errors gracefully
    except ValueError as val_err:
        print(f"⚠️ Validation Error: {str(val_err)}")
        return {"status": "error", "message": str(val_err)}
        
    # Catches system-level breaks
    except Exception as e:
        import traceback
        print("\n❌ CRITICAL CRASH LOG:")
        traceback.print_exc()
        return {"status": "error", "message": f"Server processing failed: {str(e)}"}