import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final valor = rating - i;
        final IconData icono;
        if (valor >= 1) {
          icono = Icons.star;
        } else if (valor >= 0.5) {
          icono = Icons.star_half;
        } else {
          icono = Icons.star_border;
        }
        return Icon(icono, size: size, color: Colors.amber[700]);
      }),
    );
  }
}
