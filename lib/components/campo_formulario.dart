import 'package:flutter/material.dart';

class CampoFormulario extends StatelessWidget {
  const CampoFormulario({
    super.key,
    required this.controller,
    required this.rotulo,
    this.dica,
    this.icone,
    this.validador,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.obrigatorio = false,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.sufixo,
  });

  final TextEditingController controller;
  final String rotulo;
  final String? dica;
  final IconData? icone;
  final String? Function(String?)? validador;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final bool obrigatorio;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final Widget? sufixo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: rotulo,
          hintText: dica,
          prefixIcon: icone == null ? null : Icon(icone),
          suffixIcon: sufixo,
        ),
        validator: (value) {
          if (obrigatorio && (value == null || value.trim().isEmpty)) {
            return 'Campo obrigatório';
          }
          return validador?.call(value);
        },
      ),
    );
  }
}
