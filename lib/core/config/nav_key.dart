import 'package:flutter/material.dart';

/// Clave global del Navigator raiz. Se pasa a MaterialApp.navigatorKey
/// para permitir navegacion desde fuera del arbol de widgets
/// (interceptor de red, servicio de notificaciones).
final appNavigatorKey = GlobalKey<NavigatorState>();
