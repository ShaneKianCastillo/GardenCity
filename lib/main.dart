import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencity/guides/dry_season.dart';
import 'package:gardencity/guides/fertilizing_process.dart';
import 'package:gardencity/guides/planting_process.dart';
import 'package:gardencity/guides/pruning_process.dart';
import 'package:gardencity/guides/soil_types.dart';
import 'package:gardencity/guides/wet_season.dart';
import 'package:gardencity/notif_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'api/firebase_api.dart';
import 'firebase_options.dart';
import 'guides/seasonal_plants.dart';
import 'notifications/local_notifs.dart';

import 'auth/login.dart';
import 'components/dashboard.dart';
import 'components/my_garden.dart';
import 'components/gardening_guides.dart';
import 'components/schedule_page.dart';

const kDarkGreen = Color(0xFF004643);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env, Firebase, FCM, local notifications (with tz + permissions inside init)
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().init();           // your FCM token/handlers
  await LocalNotifs.instance.init();    // tz init + Android 13+ permission request
  await LocalNotifs.instance.ensureExactAlarmAllowed();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kDarkGreen,
        primary: kDarkGreen,
        onPrimary: Colors.white,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Garden City',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kDarkGreen,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: kDarkGreen, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kDarkGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const LoginPage(),
      routes: {
        LoginPage.routeName: (_) => const LoginPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/my-garden': (_) => const MyGarden(),
        '/guides': (_) => const GardeningGuides(),
        '/schedule': (_) => const SchedulePage(),
        '/soil-types': (_)=> const SoilTypes(),
        '/seasonal-plants': (_)=> const SeasonalPlants(),
        '/dry-season': (_)=> const DrySeason(),
        '/wet-season': (_)=> const WetSeason(),
        '/fertilizing-process': (_)=> const FertilizingProcess(),
        '/planting-process': (_)=> const PlantingProcess(),
        '/pruning-process': (_)=> const PruningProcess(),
      },
    );
  }
}
