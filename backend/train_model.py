import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import make_pipeline
import joblib

print("1. Loading your Kaggle dataset...")
df = pd.read_csv('upi_transactions_2024.csv')

print("2. Engineering the missing 'Narration' column...")
narration_keywords = {
    'Grocery': ['BLINKIT', 'ZEPTO', 'BIGBASKET', 'DMART', 'RELIANCE_FRESH', 'INSTAMART', 'GROCERIES'],
    'Food': ['ZOMATO', 'SWIGGY', 'MCDONALDS', 'STARBUCKS', 'DOMINOS_PIZZA', 'DINNER', 'RESTAURANT'],
    'Shopping': ['AMAZON', 'FLIPKART', 'MYNTRA', 'NYKAA', 'ZUDIO', 'DECATHLON_SPORTS', 'LIFESTYLE', 'IPHONE', 'SHOPPING'],
    'Fuel': ['INDIANOIL', 'HPCL', 'BPCL', 'SHELL'],
    'Entertainment': ['NETFLIX', 'SPOTIFY', 'BOOKMYSHOW', 'PVR', 'CONCERT'],
    'Utilities': ['ELECTRICITY', 'AIRTEL_FIBER', 'JIO', 'BESCOM', 'INDANE_GAS', 'WATER_BOARD', 'MAINTENANCE'],
    'Transport': ['UBER', 'OLA', 'RAPIDO', 'IRCTC', 'FLIGHT'],
    'Healthcare': ['APOLLO_PHARMACY', 'PHARMEASY', 'MEDPLUS', 'HOSPITAL', 'CLINIC', '1MG', 'PRACTO'],
    'Rent': ['HDFC_RENT', 'RENT_PAYMENT', 'HOUSE_RENT'], 
    'Investment': ['HDFC_HOME_LOAN_EMI', 'MUTUAL_FUND', 'STOCK_MARKET'],
    'Other': ['TRANSFER', 'NEFT', 'IMPS', 'ATM_WITHDRAWAL', 'SALARY']
}

def generate_narration(row):
    category = row['merchant_category']
    keyword = np.random.choice(narration_keywords.get(category, ['MISC']))
    ref_num = np.random.randint(10000000, 99999999)
    
    # Randomly assign realistic banking prefixes so the AI learns them all!
    prefix = np.random.choice(['UPI/P2M', 'BIL', 'POS', 'UPI/P2P', 'NEFT'])
    return f"{prefix}/{keyword}/{ref_num}"


df['Narration'] = df.apply(generate_narration, axis=1)

print("3. Training the Custom AI Model on 250,000 rows...")

ai_pipeline = make_pipeline(
    TfidfVectorizer(lowercase=True),
    MultinomialNB()
)


ai_pipeline.fit(df['Narration'], df['merchant_category'])

print("4. Saving the AI Brain...")
joblib.dump(ai_pipeline, 'bank_transaction_classifier.pkl')
print("✅ SUCCESS: Model saved as 'bank_transaction_classifier.pkl'")