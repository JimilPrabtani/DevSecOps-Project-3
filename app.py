import os
import html
import logging
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from config import Config
from models import db, Message

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger('devsecops-app')

app = Flask(__name__)
app.config.from_object(Config)

# Security Middlewares
CORS(app, resources={r"/api/*": {"origins": "*"}})
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=[app.config['RATELIMIT_DEFAULT']],
    storage_uri=app.config['RATELIMIT_STORAGE_URI']
)

# Initialize Database
db.init_app(app)

with app.app_context():
    try:
        db.create_all()
        logger.info("Database tables verified/initialized successfully.")
    except Exception as e:
        logger.error(f"Database initialization error: {e}")

# Security Headers Middleware
@app.after_request
def apply_security_headers(response):
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Content-Security-Policy'] = "default-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com https://code.jquery.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com;"
    return response

# Routes
@app.route('/')
def index():
    try:
        messages = Message.query.order_by(Message.id.asc()).all()
        messages_tuples = [(m.message,) for m in messages]
        return render_template('index.html', messages=messages_tuples)
    except Exception as e:
        logger.error(f"Error fetching messages for index: {e}")
        return render_template('index.html', messages=[])

@app.route('/submit', methods=['POST'])
@limiter.limit("10 per minute")
def submit():
    new_message_raw = request.form.get('new_message', '').strip()
    
    if not new_message_raw:
        return jsonify({'error': 'Message content cannot be empty'}), 400

    if len(new_message_raw) > 500:
        return jsonify({'error': 'Message exceeds maximum length of 500 characters'}), 400

    # Sanitize user input against XSS
    sanitized_message = html.escape(new_message_raw)

    try:
        msg_obj = Message(message=sanitized_message)
        db.session.add(msg_obj)
        db.session.commit()
        logger.info(f"New message created with ID: {msg_obj.id}")
        return jsonify({'message': sanitized_message, 'status': 'success'}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to insert message into database: {e}")
        return jsonify({'error': 'Database transaction failed'}), 500

# REST API Endpoints
@app.route('/api/v1/messages', methods=['GET'])
def get_messages_api():
    try:
        messages = Message.query.order_by(Message.created_at.desc()).all()
        return jsonify({
            'status': 'success',
            'count': len(messages),
            'data': [m.to_dict() for m in messages]
        }), 200
    except Exception as e:
        logger.error(f"API Error fetching messages: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/messages', methods=['POST'])
@limiter.limit("10 per minute")
def post_message_api():
    data = request.get_json(silent=True) or {}
    new_message_raw = data.get('message', '').strip()
    
    if not new_message_raw:
        return jsonify({'error': 'JSON payload must contain a non-empty "message" field'}), 400

    if len(new_message_raw) > 500:
        return jsonify({'error': 'Message exceeds 500 characters'}), 400

    sanitized_message = html.escape(new_message_raw)

    try:
        msg_obj = Message(message=sanitized_message)
        db.session.add(msg_obj)
        db.session.commit()
        return jsonify({'status': 'success', 'data': msg_obj.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"API Error saving message: {e}")
        return jsonify({'error': 'Database insertion failed'}), 500

@app.route('/health', methods=['GET'])
@app.route('/api/v1/health', methods=['GET'])
def health():
    try:
        # Check Database Connection Readiness
        db.session.execute(db.select(1)).first()
        db_status = "healthy"
    except Exception as e:
        logger.error(f"Healthcheck DB failure: {e}")
        db_status = f"unhealthy: {str(e)}"

    status_code = 200 if db_status == "healthy" else 503
    return jsonify({
        'status': 'UP' if db_status == "healthy" else 'DOWN',
        'database': db_status,
        'environment': os.environ.get('FLASK_ENV', 'production')
    }), status_code

@app.route('/api/v1/metrics', methods=['GET'])
def metrics():
    try:
        msg_count = Message.query.count()
        return jsonify({
            'status': 'success',
            'metrics': {
                'total_messages': msg_count,
                'app_name': 'devsecops-3tier-flask',
                'version': '2.0.0'
            }
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    # Bind to localhost by default; override via FLASK_HOST env for container/network access
    host = os.environ.get('FLASK_HOST', '127.0.0.1')
    app.run(host=host, port=port, debug=False)