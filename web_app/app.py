from flask import Flask, request, jsonify
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "status": "running",
        "message": "Travel Cost Calculator API is running"
    })

@app.route('/api/calculate', methods=['POST'])
def calculate_cost():
    data = request.get_json()
    
    # Extract data from request
    distance = float(data.get('distance', 0))
    fuel_price = float(data.get('fuelPrice', 0))
    fuel_efficiency = float(data.get('fuelEfficiency', 0))
    
    # Calculate costs
    fuel_cost = (distance / fuel_efficiency) * fuel_price
    
    return jsonify({
        "fuelCost": round(fuel_cost, 2),
        "distance": distance,
        "fuelPrice": fuel_price,
        "fuelEfficiency": fuel_efficiency
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8001))
    app.run(host='0.0.0.0', port=port) 