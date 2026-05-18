import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'hallmaster_enterprise.db');
    
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Halls table
    await db.execute('''
      CREATE TABLE halls (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        base_price REAL NOT NULL,
        amenities TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Add-on services table
    await db.execute('''
      CREATE TABLE add_on_services (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Bookings table
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        hall_id TEXT NOT NULL,
        booking_date TEXT NOT NULL,
        start_hour INTEGER NOT NULL,
        end_hour INTEGER NOT NULL,
        status TEXT NOT NULL,
        final_price REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cancelled_at TEXT,
        cancellation_reason TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (hall_id) REFERENCES halls(id)
      )
    ''');

    // Booking services junction table (many-to-many)
    await db.execute('''
      CREATE TABLE booking_services (
        booking_id TEXT NOT NULL,
        service_id TEXT NOT NULL,
        PRIMARY KEY (booking_id, service_id),
        FOREIGN KEY (booking_id) REFERENCES bookings(id),
        FOREIGN KEY (service_id) REFERENCES add_on_services(id)
      )
    ''');

    // Audit logs table
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        actor_id TEXT NOT NULL,
        changes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Seed initial data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed halls
    await db.insert('halls', {
      'id': 'h1',
      'name': 'Prime Ballroom',
      'location': 'Kuala Lumpur',
      'capacity': 350,
      'base_price': 1200.0,
      'amenities': 'Stage,Wi-Fi,Parking',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('halls', {
      'id': 'h2',
      'name': 'Orchid Conference Hall',
      'location': 'Cyberjaya',
      'capacity': 120,
      'base_price': 680.0,
      'amenities': 'Projector,Coffee Bar',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('halls', {
      'id': 'h3',
      'name': 'Zenith Boardroom',
      'location': 'Putrajaya',
      'capacity': 40,
      'base_price': 320.0,
      'amenities': 'Smart Display,Soundproof',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Seed services
    await db.insert('add_on_services', {
      'id': 's1',
      'name': 'AV Equipment',
      'unit_price': 180.0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('add_on_services', {
      'id': 's2',
      'name': 'Catering Package',
      'unit_price': 350.0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('add_on_services', {
      'id': 's3',
      'name': 'Decor Setup',
      'unit_price': 220.0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
