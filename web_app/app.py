from flask import Flask, request, jsonify, render_template
import os
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

load_dotenv()

# Create Flask app with explicit template folder
template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), 'templates'))
logger.debug(f"Template directory: {template_dir}")
logger.debug(f"Template exists: {os.path.exists(os.path.join(template_dir, 'index.html'))}")

app = Flask(__name__, template_folder=template_dir)

# Set the application root to /travelcalc/
app.config['APPLICATION_ROOT'] = '/travelcalc'

@app.route('/')
def home():
    logger.debug("Home route accessed")
    try:
        return render_template('index.html')
    except Exception as e:
        logger.error(f"Error rendering template: {str(e)}")
        return jsonify({"error": str(e)}), 500

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