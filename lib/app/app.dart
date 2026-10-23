import 'package:flutter/material.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:calium_stream/app/router.dart';
import 'package:calium_stream/core/theme/app_theme.dart';
import 'package:calium_stream/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calium_stream/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:calium_stream/features/home/presentation/bloc/home_bloc.dart';
import 'package:calium_stream/features/search/presentation/bloc/search_bloc.dart';
import 'package:calium_stream/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:calium_stream/features/social/presentation/bloc/social_bloc.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';
import 'package:calium_stream/features/user_lists/presentation/bloc/user_lists_bloc.dart';
import 'package:calium_stream/features/settings/presentation/bloc/settings_bloc.dart';

class CaliumApp extends StatelessWidget {
  const CaliumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AccountSession.instance,
      builder: (context, _) => MultiBlocProvider(
      key: ValueKey(AccountSession.instance.generation),
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => GetIt.I<AuthBloc>()..add(CheckAuthRequested()),
        ),
        BlocProvider<HomeBloc>(
          create: (_) => GetIt.I<HomeBloc>()..add(LoadHomeFeedRequested()),
        ),
        BlocProvider<ExploreBloc>(create: (_) => GetIt.I<ExploreBloc>()),
        BlocProvider<SocialBloc>(create: (_) => GetIt.I<SocialBloc>()),
        BlocProvider<SearchBloc>(create: (_) => GetIt.I<SearchBloc>()),
        BlocProvider<LibraryBloc>(
          create: (_) => GetIt.I<LibraryBloc>()..add(LoadLibraryRequested()),
        ),
        BlocProvider<CalendarBloc>(create: (_) => GetIt.I<CalendarBloc>()),
        BlocProvider<UserListsBloc>(
          create: (_) =>
              GetIt.I<UserListsBloc>()..add(LoadUserListsRequested()),
        ),
        BlocProvider<SettingsBloc>(create: (_) => GetIt.I<SettingsBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Calium',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        routerConfig: AppRouter.router,
      ),
    ));
  }
}
