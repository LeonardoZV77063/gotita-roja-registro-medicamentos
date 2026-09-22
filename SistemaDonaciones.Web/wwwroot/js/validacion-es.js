// Mensajes en español y números flexibles alineados con EnlazadorDecimal.
// Las reglas data-val-* emitidas por el modelo conservan prioridad.

(function ($) {
    'use strict';

    if (!$ || !$.validator) return;

    function aFechaLegible(valor) {
        var partes = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(valor));
        return partes ? partes[3] + '/' + partes[2] + '/' + partes[1] : valor;
    }

    function esFecha(elemento) {
        return elemento && elemento.type === 'date';
    }

    $.extend($.validator.messages, {
        required: 'Este campo es obligatorio.',
        remote: 'Revise este campo.',
        email: 'Escriba un correo electrónico válido.',
        url: 'Escriba una dirección web válida.',
        date: 'Escriba una fecha válida.',
        dateISO: 'Escriba una fecha válida.',
        number: 'Escriba un número válido.',
        digits: 'Escriba sólo dígitos.',
        creditcard: 'Escriba un número de tarjeta válido.',
        equalTo: 'Escriba el mismo valor otra vez.',
        extension: 'El tipo de archivo no está permitido.',
        maxlength: $.validator.format('Escriba como máximo {0} caracteres.'),
        minlength: $.validator.format('Escriba al menos {0} caracteres.'),
        rangelength: $.validator.format('Escriba entre {0} y {1} caracteres.'),
        range: $.validator.format('Escriba un valor entre {0} y {1}.'),
        step: $.validator.format('Use múltiplos de {0} (por ejemplo, hasta dos decimales).'),
        max: function (parametro, elemento) {
            return esFecha(elemento)
                ? 'La fecha no puede ser posterior al ' + aFechaLegible(parametro) + '.'
                : 'Escriba un valor menor o igual a ' + parametro + '.';
        },
        min: function (parametro, elemento) {
            return esFecha(elemento)
                ? 'La fecha no puede ser anterior al ' + aFechaLegible(parametro) + '.'
                : 'Escriba un valor mayor o igual a ' + parametro + '.';
        }
    });

    // ── Números con coma o punto ────────────────────────────────────────────
    // Misma regla que NumeroFlexible en el servidor: si hay punto y coma, el
    // último es el decimal; un único separador que aparece una sola vez es el
    // decimal; repetido, es de miles y los grupos deben ser de tres dígitos.
    function aNumero(texto) {
        var limpio = String(texto).replace(/\s/g, '');
        if (!limpio) return NaN;

        var puntos = (limpio.match(/\./g) || []).length;
        var comas = (limpio.match(/,/g) || []).length;
        var decimal = null;
        var miles = null;

        if (puntos > 0 && comas > 0) {
            decimal = limpio.lastIndexOf('.') > limpio.lastIndexOf(',') ? '.' : ',';
            miles = decimal === '.' ? ',' : '.';
            if ((decimal === '.' ? puntos : comas) > 1) return NaN;
        } else if (puntos + comas > 0) {
            var separador = puntos > 0 ? '.' : ',';
            if (puntos + comas === 1) decimal = separador; else miles = separador;
        }

        if (miles) {
            var entera = decimal ? limpio.slice(0, limpio.lastIndexOf(decimal)) : limpio;
            var grupos = entera.replace(/^[-+]/, '').split(miles);
            if (grupos[0].length === 0 || grupos[0].length > 3) return NaN;
            for (var i = 1; i < grupos.length; i++) {
                if (grupos[i].length !== 3) return NaN;
            }
            limpio = limpio.split(miles).join('');
        }

        if (decimal === ',') limpio = limpio.replace(',', '.');

        return /^[-+]?(\d+\.?\d*|\.\d+)$/.test(limpio) ? parseFloat(limpio) : NaN;
    }

    $.validator.numeroFlexible = aNumero;

    $.validator.methods.number = function (valor, elemento) {
        return this.optional(elemento) || !isNaN(aNumero(valor));
    };

    $.validator.methods.min = function (valor, elemento, parametro) {
        if (this.optional(elemento)) return true;
        if (esFecha(elemento)) return valor >= parametro;
        var n = aNumero(valor);
        return !isNaN(n) && n >= parseFloat(parametro);
    };

    $.validator.methods.max = function (valor, elemento, parametro) {
        if (this.optional(elemento)) return true;
        if (esFecha(elemento)) return valor <= parametro;
        var n = aNumero(valor);
        return !isNaN(n) && n <= parseFloat(parametro);
    };

    $.validator.methods.range = function (valor, elemento, parametros) {
        if (this.optional(elemento)) return true;
        var n = aNumero(valor);
        return !isNaN(n) && n >= parseFloat(parametros[0]) && n <= parseFloat(parametros[1]);
    };
})(window.jQuery);
