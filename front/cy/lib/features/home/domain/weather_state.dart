import 'weather_data.dart';

sealed class WeatherState {
  const WeatherState();
}

class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

class WeatherLoaded extends WeatherState {
  final WeatherData data;

  const WeatherLoaded(this.data);
}

class WeatherError extends WeatherState {
  final String message;

  const WeatherError(this.message);
}
