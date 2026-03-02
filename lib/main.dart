import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'data/datasources/local/hive_service.dart';
import 'data/models/face_embedding_model.dart';
import 'presentation/providers/face_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'core/theme/app_theme.dart';

/// Application entry point.
/// Initializes Hive, registers type adapters, and bootstraps DI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent face detection
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive type adapters
  if (!Hive.isAdapterRegistered(FaceEmbeddingModelAdapter().typeId)) {
    Hive.registerAdapter(FaceEmbeddingModelAdapter());
  }

  // Open Hive box for face embeddings
  await Hive.openBox<FaceEmbeddingModel>(HiveService.faceEmbeddingsBoxName);

  // Initialize service locator (dependency injection)
  await ServiceLocator.init();

  runApp(const RecognitionsApp());
}

/// Root widget of the application.
class RecognitionsApp extends StatelessWidget {
  const RecognitionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FaceProvider>(
          create: (_) => ServiceLocator.get<FaceProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'Face Recognitions',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
