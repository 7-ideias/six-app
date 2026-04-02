import '../core/utils/color_mapper.dart';
import '../data/models/aparencia_models.dart';
import '../domain/models/aparencia_models.dart';

class ConfiguracaoAparenciaMapper {
  static ConfiguracaoAparenciaSistema fromResponse(ConfiguracaoAparenciaResponse response) {
    return ConfiguracaoAparenciaSistema(
      id: response.id,
      idEmpresa: response.idEmpresa,
      tema: _mapTemaFromString(response.tema),
      paleta: _mapPaletaFromDto(response.paleta),
    );
  }

  static SalvarConfiguracaoAparenciaRequest toRequest(ConfiguracaoAparenciaSistema dominio) {
    return SalvarConfiguracaoAparenciaRequest(
      idEmpresa: dominio.idEmpresa,
      tema: dominio.tema.name.toUpperCase(),
      paleta: _mapPaletaToDto(dominio.paleta),
    );
  }

  static TemaSistema _mapTemaFromString(String tema) {
    switch (tema.toUpperCase()) {
      case 'CLARO':
        return TemaSistema.claro;
      case 'ESCURO':
        return TemaSistema.escuro;
      case 'AUTOMATICO':
      case 'AUTOMÁTICO':
        return TemaSistema.automatico;
      default:
        return TemaSistema.claro;
    }
  }

  static PaletaSistema _mapPaletaFromDto(PaletaSistemaDto dto) {
    return PaletaSistema(
      primaria: ColorMapper.fromHex(dto.primaria),
      secundaria: ColorMapper.fromHex(dto.secundaria),
      destaque: ColorMapper.fromHex(dto.destaque),
      alerta: ColorMapper.fromHex(dto.alerta),
      fundo: ColorMapper.fromHex(dto.fundo),
      superficie: ColorMapper.fromHex(dto.superficie),
      textoPrimario: ColorMapper.fromHex(dto.textoPrimario),
      textoSecundario: ColorMapper.fromHex(dto.textoSecundario),
    );
  }

  static PaletaSistemaDto _mapPaletaToDto(PaletaSistema paleta) {
    return PaletaSistemaDto(
      primaria: ColorMapper.toHex(paleta.primaria),
      secundaria: ColorMapper.toHex(paleta.secundaria),
      destaque: ColorMapper.toHex(paleta.destaque),
      alerta: ColorMapper.toHex(paleta.alerta),
      fundo: ColorMapper.toHex(paleta.fundo),
      superficie: ColorMapper.toHex(paleta.superficie),
      textoPrimario: ColorMapper.toHex(paleta.textoPrimario),
      textoSecundario: ColorMapper.toHex(paleta.textoSecundario),
    );
  }
}
