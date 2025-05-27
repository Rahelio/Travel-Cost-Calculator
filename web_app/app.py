from flask import Flask, request, jsonify, render_template
import os
from dotenv import load_dotenv

load_dotenv()

# Create Flask app with explicit template folder
template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), 'templates'))
app = Flask(__name__, template_folder=template_dir)

# Set the application root to /travelcalc/
app.config['APPLICATION_ROOT'] = '/travelcalc'

@app.route('/')
def home():
    return render_template('index.html')

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