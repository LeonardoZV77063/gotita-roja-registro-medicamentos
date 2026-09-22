// Comportamiento compartido de la interfaz. Depende de jQuery y Bootstrap.

(function () {
    'use strict';

    // ── Tema claro / oscuro ─────────────────────────────────────────────────
    // El tema ya viene aplicado sobre <html>: _Layout lo resuelve en un script
    // en línea, antes de pintar, para que no haya un destello claro al cargar.
    // Acá sólo se atiende el botón y se recuerda la elección.
    //
    // La preferencia es por equipo, no por usuaria: va en localStorage y no en
    // el perfil. Quien atiende suele compartir la máquina del puesto, y el
    // ajuste depende más de la luz de la sala que de quién esté con la sesión
    // abierta. Guardarlo en el servidor obligaría además a una migración para
    // algo que no es un dato del negocio.
    var CLAVE_TEMA = 'gotitaroja.tema';

    function temaGuardado() {
        // En navegación privada o con las cookies bloqueadas, leer localStorage
        // lanza. Sin preferencia guardada se sigue la del sistema.
        try {
            return window.localStorage.getItem(CLAVE_TEMA);
        } catch (e) {
            return null;
        }
    }

    function recordarTema(tema) {
        try {
            window.localStorage.setItem(CLAVE_TEMA, tema);
        } catch (e) {
            /* Sin persistencia el tema dura lo que la pestaña; no es motivo
               para dejar el botón sin efecto. */
        }
    }

    function prepararTema() {
        var boton = document.querySelector('[data-conmuta-tema]');
        if (!boton) return;

        var etiqueta = boton.querySelector('[data-texto-tema]');
        var icono = boton.querySelector('[data-icono-tema]');

        function pintar(tema) {
            var oscuro = tema === 'oscuro';

            document.documentElement.setAttribute('data-tema', tema);
            boton.setAttribute('aria-pressed', oscuro ? 'true' : 'false');
            boton.setAttribute(
                'title',
                oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro');

            if (icono) icono.textContent = oscuro ? '☀' : '☾';
            if (etiqueta) etiqueta.textContent = oscuro ? 'Claro' : 'Oscuro';
        }

        pintar(document.documentElement.getAttribute('data-tema') === 'oscuro'
            ? 'oscuro'
            : 'claro');

        boton.addEventListener('click', function () {
            var nuevo =
                document.documentElement.getAttribute('data-tema') === 'oscuro'
                    ? 'claro'
                    : 'oscuro';

            pintar(nuevo);
            recordarTema(nuevo);
        });

        // Si nunca se eligió a mano, el tema sigue al del sistema operativo
        // mientras la pestaña está abierta.
        if (temaGuardado()) return;
        if (!window.matchMedia) return;

        var consulta = window.matchMedia('(prefers-color-scheme: dark)');
        var alCambiar = function (evento) {
            if (temaGuardado()) return;
            pintar(evento.matches ? 'oscuro' : 'claro');
        };

        // Safari antiguo no implementa addEventListener sobre MediaQueryList.
        if (consulta.addEventListener) {
            consulta.addEventListener('change', alCambiar);
        } else if (consulta.addListener) {
            consulta.addListener(alCambiar);
        }
    }

    // ── Autocompletado ──────────────────────────────────────────────────────
    // data-autocompletar aporta sugerencias sin restringir el texto libre.
    function prepararAutocompletado(input) {
        if (input.dataset.autocompletadoListo === '1') return;
        input.dataset.autocompletadoListo = '1';

        var url = input.dataset.autocompletar;
        var contenedor = document.createElement('div');
        contenedor.className = 'lista-sugerencias';

        var envoltorio = input.parentElement;
        if (!envoltorio.classList.contains('envoltorio-autocompletado')) {
            envoltorio.classList.add('envoltorio-autocompletado');
        }
        envoltorio.appendChild(contenedor);

        var temporizador = null;
        var indiceActivo = -1;

        function cerrar() {
            contenedor.style.display = 'none';
            indiceActivo = -1;
        }

        function pintar(opciones) {
            contenedor.innerHTML = '';

            if (!opciones || opciones.length === 0) {
                cerrar();
                return;
            }

            opciones.forEach(function (texto) {
                var fila = document.createElement('div');
                fila.textContent = texto;
                fila.addEventListener('mousedown', function (e) {
                    e.preventDefault();
                    input.value = texto;
                    cerrar();
                    input.dispatchEvent(new Event('change', { bubbles: true }));
                });
                contenedor.appendChild(fila);
            });

            contenedor.style.display = 'block';
        }

        input.addEventListener('input', function () {
            clearTimeout(temporizador);
            var termino = input.value.trim();

            if (termino.length < 2) {
                cerrar();
                return;
            }

            temporizador = setTimeout(function () {
                fetch(url + '?termino=' + encodeURIComponent(termino))
                    .then(function (r) { return r.ok ? r.json() : []; })
                    .then(pintar)
                    .catch(cerrar);
            }, 220);
        });

        input.addEventListener('keydown', function (e) {
            var filas = contenedor.querySelectorAll('div');
            if (contenedor.style.display !== 'block' || filas.length === 0) return;

            if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
                e.preventDefault();
                filas.forEach(function (f) { f.classList.remove('activa'); });
                indiceActivo = e.key === 'ArrowDown'
                    ? Math.min(indiceActivo + 1, filas.length - 1)
                    : Math.max(indiceActivo - 1, 0);
                filas[indiceActivo].classList.add('activa');
            } else if (e.key === 'Enter' && indiceActivo >= 0) {
                e.preventDefault();
                input.value = filas[indiceActivo].textContent;
                cerrar();
                input.dispatchEvent(new Event('change', { bubbles: true }));
            } else if (e.key === 'Escape') {
                cerrar();
            }
        });

        input.addEventListener('blur', function () {
            setTimeout(cerrar, 150);
        });
    }

    // ── Edad calculada al escribir la fecha de nacimiento ───────────────────
    function prepararEdad() {
        var campoFecha = document.querySelector('[data-calcula-edad]');
        if (!campoFecha) return;

        var destino = document.querySelector(campoFecha.dataset.calculaEdad);
        if (!destino) return;

        function calcular() {
            if (!campoFecha.value) {
                destino.textContent = '';
                return;
            }

            var nacimiento = new Date(campoFecha.value + 'T00:00:00');
            if (isNaN(nacimiento.getTime())) {
                destino.textContent = '';
                return;
            }

            var hoy = new Date();
            var edad = hoy.getFullYear() - nacimiento.getFullYear();
            var mes = hoy.getMonth() - nacimiento.getMonth();

            if (mes < 0 || (mes === 0 && hoy.getDate() < nacimiento.getDate())) edad--;

            destino.textContent = edad >= 0
                ? edad + (edad === 1 ? ' año' : ' años')
                : '';
        }

        campoFecha.addEventListener('change', calcular);
        campoFecha.addEventListener('input', calcular);
        calcular();
    }

    // ── Filtro de teclado ───────────────────────────────────────────────────
    // Cada filtro debe mantenerse alineado con la expresión regular del modelo;
    // también procesa texto pegado, arrastrado o completado por el navegador.
    var FILTROS_ENTRADA = {
        digitos: /[0-9]/,
        alfanumerico: /[0-9A-Za-z]/,
        soloLetras: /[A-Za-z]/,
        letras: /[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ '\-]/,
        telefono: /[0-9 +\-]/
    };

    function filtrarTexto(texto, permitido, mayusculas) {
        // Apóstrofos tipográficos (los que ponen los teclados del celular) y
        // espacios no separables se llevan a su forma simple antes de filtrar.
        // NFC junta la vocal y su tilde cuando el texto pegado las trae
        // separadas; sin eso la tilde se descartaría como carácter extraño.
        if (texto.normalize) texto = texto.normalize('NFC');

        texto = texto
            .replace(/[\u2018\u2019\u00B4\u0060]/g, "'")
            .replace(/[\u00A0\t]/g, ' ');

        if (mayusculas) texto = texto.toUpperCase();

        var resultado = '';
        Array.from(texto).forEach(function (caracter) {
            if (permitido.test(caracter)) resultado += caracter;
        });
        return resultado;
    }

    function prepararFiltrosEntrada(raiz) {
        raiz.querySelectorAll('input[data-filtro]').forEach(function (campo) {
            if (campo.dataset.filtroListo === '1') return;

            var permitido = FILTROS_ENTRADA[campo.dataset.filtro];
            if (!permitido) return;

            campo.dataset.filtroListo = '1';
            var mayusculas = campo.dataset.filtroMayusculas === 'true';
            var componiendo = false;

            function aplicar() {
                var valor = campo.value;
                var limpio = filtrarTexto(valor, permitido, mayusculas);
                if (limpio === valor) return;

                // Se conserva la posición del cursor: si se borra un carácter
                // no permitido en medio del texto, el cursor no salta al final.
                var cursor = campo.selectionStart;
                var cursorNuevo = cursor === null
                    ? null
                    : filtrarTexto(valor.slice(0, cursor), permitido, mayusculas).length;

                campo.value = limpio;

                if (cursorNuevo !== null && document.activeElement === campo) {
                    try { campo.setSelectionRange(cursorNuevo, cursorNuevo); } catch (e) { /* Algunos tipos de campo no admiten selección. */ }
                }
            }

            // Durante una composición (teclados con autocorrección o IME) no se
            // toca el valor: se filtra cuando la palabra queda confirmada.
            campo.addEventListener('compositionstart', function () { componiendo = true; });
            campo.addEventListener('compositionend', function () { componiendo = false; aplicar(); });
            campo.addEventListener('input', function (e) {
                if (componiendo || e.isComposing) return;
                aplicar();
            });

            // El valor que ya trae la página (edición, reenvío con errores) se
            // deja como está: si fuera inválido, el mensaje del servidor lo dice.
        });
    }

    // ── Líneas de medicamentos del formulario de entrega ────────────────────
    function prepararLineas() {
        var contenedor = document.getElementById('lineasMedicamentos');
        var boton = document.getElementById('agregarLinea');
        if (!contenedor || !boton) return;

        function renumerar() {
            var lineas = contenedor.querySelectorAll('.linea-medicamento');

            lineas.forEach(function (linea, indice) {

                // ASP.NET reconstruye la colección a partir de índices contiguos.
                linea.querySelectorAll('[name]').forEach(function (campo) {
                    campo.name = campo.name.replace(
                        /Lineas\[\d+\]/,
                        'Lineas[' + indice + ']'
                    );
                });

                linea.querySelectorAll('[data-numero]').forEach(function (n) {
                    n.textContent = indice + 1;
                });

                // Cada campo tiene un id único (Lineas_{n}__Campo) y su
                // etiqueta apunta a él con for: al copiar o quitar líneas hay
                // que renumerar los dos, o las etiquetas quedan asociadas al
                // campo de otra línea.
                linea.querySelectorAll('[id]').forEach(function (campo) {
                    campo.id = campo.id.replace(/Lineas_\d+__/, 'Lineas_' + indice + '__');
                });

                linea.querySelectorAll('label[for]').forEach(function (etiqueta) {
                    etiqueta.htmlFor = etiqueta.htmlFor.replace(/Lineas_\d+__/, 'Lineas_' + indice + '__');
                });
            });

            contenedor.querySelectorAll('.quitar-linea').forEach(function (b) {
                b.disabled = lineas.length === 1;
            });
        }

        boton.addEventListener('click', function () {

            var plantilla = contenedor.querySelector('.linea-medicamento');
            var copia = plantilla.cloneNode(true);

            // La copia necesita inicializar sus propios eventos FIFO.
            delete copia.dataset.fifoListo;

            copia.querySelectorAll('input').forEach(function (campo) {

                if (campo.type === 'checkbox') {
                    campo.checked = false;

                    // La línea nueva vuelve a decidir sola si descuenta del
                    // inventario: no hereda el clic manual de la anterior.
                    delete campo.dataset.tildeManual;
                }
                else if (campo.type !== 'hidden') {
                    campo.value = '';
                }

                campo.dataset.autocompletadoListo = '';
            });

            copia.querySelectorAll(
                '.lista-sugerencias, .resultado-fifo'
            ).forEach(function (n) {
                n.remove();
            });

            contenedor.appendChild(copia);

            renumerar();

            inicializar(copia);
        });

        contenedor.addEventListener('click', function (e) {
            var boton = e.target.closest('.quitar-linea');
            if (!boton) return;

            var lineas = contenedor.querySelectorAll('.linea-medicamento');
            if (lineas.length <= 1) return;

            boton.closest('.linea-medicamento').remove();
            renumerar();
        });

        renumerar();
    }

    // ── Bloques que dependen de una opción elegida ──────────────────────────
    // data-abre-bloque controla un fieldset según data-abre de la opción. Al
    // deshabilitarlo, sus campos dejan de viajar en el formulario.
    function prepararBloquesPorOpcion(raiz) {
        (raiz || document).querySelectorAll('select[data-abre-bloque]').forEach(function (select) {
            if (select.dataset.abreListo === '1') return;
            select.dataset.abreListo = '1';

            var bloque = document.querySelector(select.dataset.abreBloque);
            if (!bloque) return;

            function aplicar() {
                var elegida = select.options[select.selectedIndex];
                var abrir = !!elegida && elegida.dataset.abre === '1';

                bloque.disabled = !abrir;
                bloque.classList.toggle('d-none', !abrir);
            }

            select.addEventListener('change', aplicar);
            aplicar();
        });
    }

    // ── Stock de farmacia ───────────────────────────────────────────────────
    // El catálogo y su stock se comparten entre las líneas y la ventana de
    // selección, con una sola petición por página.
    //
    // La coincidencia por nombre repite la del servidor
    // (ServicioCatalogos.BuscarMedicamentoAsync): sin mayúsculas, sin tildes y
    // con los espacios sobrantes colapsados. Un nombre que no está en el
    // catálogo —texto libre, un medicamento nuevo— no tiene stock que descontar.
    var inventarioFarmacia = (function () {
        var url = null;
        var promesa = null;

        function normalizar(texto) {
            return (texto || '')
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .trim()
                .replace(/\s+/g, ' ')
                .toLowerCase();
        }

        function catalogo() {
            var origen = document.querySelector('[data-catalogo]');
            if (!origen) return Promise.reject(new Error('La página no declara data-catalogo.'));

            if (!promesa || url !== origen.dataset.catalogo) {
                url = origen.dataset.catalogo;

                promesa = fetch(url).then(function (r) {
                    if (!r.ok) throw new Error('No se pudo leer el catálogo: ' + r.status);
                    return r.json();
                });

                // Un fallo no queda cacheado: el próximo intento vuelve a pedirlo.
                promesa.catch(function () { promesa = null; });
            }

            return promesa;
        }

        // Unidades disponibles hoy; null si ese nombre no es un medicamento del
        // catálogo. Si el catálogo no se puede leer, la promesa se rechaza: no es
        // lo mismo «no tiene stock» que «no se pudo averiguar».
        function stockDe(nombre) {
            var buscado = normalizar(nombre);
            if (!buscado) return Promise.resolve(null);

            return catalogo().then(function (lista) {
                for (var i = 0; i < lista.length; i++) {
                    if (normalizar(lista[i].nombre) === buscado)
                        return Number(lista[i].stock) || 0;
                }

                return null;
            });
        }

        return { catalogo: catalogo, stockDe: stockDe };
    })();

    window.inventarioFarmacia = inventarioFarmacia;

    // ── Vista previa del costeo FIFO ────────────────────────────────────────
    // Consulta de qué lotes saldría la entrega antes de guardarla, para que la
    // usuaria vea el monto que el sistema va a calcular.
    function prepararSimulacionFifo(linea) {
        if (linea.dataset.fifoListo === '1') return;
        linea.dataset.fifoListo = '1';

        var casilla = linea.querySelector('[data-fifo]');
        var campoMedicamento = linea.querySelector('[data-campo="medicamento"]');
        var campoCantidad = linea.querySelector('[data-campo="cantidad"]');
        var campoMonto = linea.querySelector('[data-campo="monto"]');

        if (!casilla || !campoMedicamento || !campoCantidad) return;

        var url = casilla.dataset.fifo;

        function limpiar() {
            var previo = linea.querySelector('.resultado-fifo');
            if (previo) previo.remove();
        }

        function mostrar(html, clase) {
            limpiar();

            var caja = document.createElement('div');
            caja.className = 'resultado-fifo ' + (clase || '');
            caja.setAttribute('role', 'status');
            caja.innerHTML = html;

            linea.appendChild(caja);
        }

        // La fecha de atención excluye lotes que todavía no habían ingresado.
        var campoFecha = document.querySelector('input[name="FechaAtencion"]');

        function consultar() {
            if (!casilla.checked) {
                limpiar();

                if (campoMonto)
                    campoMonto.disabled = false;

                return;
            }

            if (campoMonto)
                campoMonto.disabled = true;

            var nombre = campoMedicamento.value.trim();
            var cantidad = parseFloat(campoCantidad.value);

            if (!nombre || !cantidad || cantidad <= 0) {
                limpiar();
                return;
            }

            fetch(
                url +
                '?medicamento=' + encodeURIComponent(nombre) +
                '&cantidad=' + encodeURIComponent(cantidad) +
                (campoFecha && campoFecha.value
                    ? '&fecha=' + encodeURIComponent(campoFecha.value)
                    : '')
            )
                .then(function (r) {
                    return r.ok ? r.json() : null;
                })
                .then(function (d) {

                    if (!d || !d.hayInventario) {
                        mostrar(
                            'Ese medicamento no tiene stock cargado en farmacia. ' +
                            'Destilde la casilla y escriba el monto a mano.'
                        );

                        return;
                    }

                    if (!d.suficiente) {
                        mostrar(
                            '<strong>Stock insuficiente.</strong> Hay ' +
                            escaparHtml(formatoCantidad(d.stockDisponible)) +
                            ' disponibles a la fecha de la entrega y se piden ' +
                            escaparHtml(formatoCantidad(cantidad)) +
                            '.' +
                            (d.lotesPosteriores
                                ? ' Parte del stock ingresó después de esa fecha y no puede usarse en esta entrega.'
                                : '')
                        );

                        return;
                    }

                    var detalle = d.lotes.map(function (l) {
                        return '<li>' +
                            escaparHtml(formatoCantidad(l.cantidad)) +
                            ' × ' +
                            escaparHtml(formatoBs(l.costoUnitario)) +
                            ' (ingreso ' +
                            escaparHtml(l.fecha) +
                            ', ' +
                            escaparHtml(l.tipoIngreso) +
                            ') = ' +
                            escaparHtml(formatoBs(l.subtotal)) +
                            '</li>';
                    }).join('');

                    mostrar(
                        '<strong>Se descontará así (del lote más antiguo al más nuevo):</strong>' +
                        '<ul class="mb-1 ps-3">' +
                        detalle +
                        '</ul>' +
                        'Monto de la donación: <strong>' +
                        formatoBs(d.monto) +
                        '</strong>'
                    );
                })
                .catch(limpiar);
        }

        // El stock decide el valor inicial; una elección manual impide cambios
        // automáticos posteriores en esa línea.
        casilla.addEventListener('change', function () {
            casilla.dataset.tildeManual = '1';
            consultar();
        });

        campoMedicamento.addEventListener('change', function () {
            if (casilla.dataset.tildeManual === '1') {
                consultar();
                return;
            }

            inventarioFarmacia.stockDe(campoMedicamento.value)
                .then(function (stock) {
                    casilla.checked = stock !== null && stock > 0;
                })
                .catch(function () {
                    // Sin catálogo no se decide por la operadora: la casilla
                    // queda como está y la vista previa avisa si no hay stock.
                })
                .then(consultar);
        });

        campoCantidad.addEventListener('change', consultar);
        if (campoFecha) campoFecha.addEventListener('change', consultar);

        consultar();
    }

    function formatoBs(valor) {
        return Number(valor).toLocaleString('es-BO', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }) + ' Bs';
    }

    function formatoCantidad(valor) {
        return Number(valor).toLocaleString('es-BO', { maximumFractionDigits: 2 });
    }

    function escaparHtml(texto) {
        return String(texto === null || texto === undefined ? '' : texto)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    // ── Fechas relacionadas ─────────────────────────────────────────────────
    // data-fecha-posterior-a="#OtroCampo": el calendario no deja elegir una
    // fecha igual o anterior a la del otro campo (por ejemplo, el vencimiento
    // de un lote respecto de su ingreso). El servidor lo valida igual.
    function prepararFechasRelacionadas() {
        document.querySelectorAll('input[data-fecha-posterior-a]').forEach(function (campo) {
            var origen = document.querySelector(campo.dataset.fechaPosteriorA);
            if (!origen) return;

            function actualizar() {
                if (!origen.value) {
                    campo.removeAttribute('min');
                    return;
                }

                var fecha = new Date(origen.value + 'T00:00:00');
                if (isNaN(fecha.getTime())) return;

                fecha.setDate(fecha.getDate() + 1);
                var mes = String(fecha.getMonth() + 1).padStart(2, '0');
                var dia = String(fecha.getDate()).padStart(2, '0');
                campo.min = fecha.getFullYear() + '-' + mes + '-' + dia;
            }

            origen.addEventListener('change', actualizar);
            actualizar();
        });
    }

    // ── Enlaces que dependen de un período ──────────────────────────────────
    // data-periodo-desde / data-periodo-hasta: el enlace toma las fechas que
    // están escritas en el formulario en el momento del clic.
    function prepararEnlacesConPeriodo() {
        document.querySelectorAll('a[data-periodo-desde][data-periodo-hasta]').forEach(function (enlace) {
            var desde = document.querySelector(enlace.dataset.periodoDesde);
            var hasta = document.querySelector(enlace.dataset.periodoHasta);
            if (!desde || !hasta) return;

            enlace.addEventListener('click', function () {
                var url = new URL(enlace.href, window.location.href);
                url.searchParams.set('desde', desde.value);
                url.searchParams.set('hasta', hasta.value);
                enlace.href = url.toString();
            });
        });
    }

    // ── Confirmaciones ──────────────────────────────────────────────────────
    var controladorConfirmacionDestructiva = null;

    function crearControladorConfirmacionDestructiva() {
        var modalEl = document.getElementById('modalConfirmacionDestructiva');
        if (!modalEl || !window.bootstrap || !window.bootstrap.Modal) return null;

        var modal = window.bootstrap.Modal.getOrCreateInstance
            ? window.bootstrap.Modal.getOrCreateInstance(modalEl)
            : new window.bootstrap.Modal(modalEl);
        var titulo = modalEl.querySelector('#tituloConfirmacionDestructiva');
        var mensaje = modalEl.querySelector('#mensajeConfirmacionDestructiva');
        var estado = modalEl.querySelector('#estadoConfirmacionDestructiva');
        var botonCancelar = modalEl.querySelector('[data-confirmacion-cancelar]');
        var botonAceptar = modalEl.querySelector('[data-confirmacion-aceptar]');
        var textoAccion = modalEl.querySelector('[data-confirmacion-accion]');
        var contador = modalEl.querySelector('[data-confirmacion-contador]');

        var formularioPendiente = null;
        var botonEnvioPendiente = null;
        var accionPendiente = 'Confirmar';
        var segundosRestantes = 3;
        var instanteDesbloqueo = 0;
        var temporizador = null;
        var envioEnCurso = false;

        function detenerTemporizador() {
            if (temporizador !== null) {
                window.clearInterval(temporizador);
                temporizador = null;
            }
        }

        function actualizarBloqueo() {
            var bloqueado = segundosRestantes > 0;
            botonAceptar.disabled = bloqueado;
            textoAccion.textContent = accionPendiente;
            contador.textContent = bloqueado ? ' (' + segundosRestantes + ')' : '';

            if (bloqueado) {
                estado.textContent = 'Podrá confirmar en ' + segundosRestantes +
                    (segundosRestantes === 1 ? ' segundo.' : ' segundos.');
            } else {
                estado.textContent = 'Ya puede confirmar la acción o cancelarla.';
            }
        }

        function actualizarDesdeReloj() {
            var nuevosSegundos = Math.max(
                0,
                Math.ceil((instanteDesbloqueo - Date.now()) / 1000)
            );
            if (nuevosSegundos !== segundosRestantes) {
                segundosRestantes = nuevosSegundos;
                actualizarBloqueo();
            }

            if (segundosRestantes <= 0) detenerTemporizador();
        }

        function iniciarTemporizador() {
            detenerTemporizador();
            instanteDesbloqueo = Date.now() + 3000;
            actualizarDesdeReloj();

            temporizador = window.setInterval(function () {
                actualizarDesdeReloj();
            }, 250);
        }

        modalEl.addEventListener('shown.bs.modal', function () {
            iniciarTemporizador();
            botonCancelar.focus();
        });

        modalEl.addEventListener('hidden.bs.modal', function () {
            detenerTemporizador();
            var botonParaRestaurarFoco = botonEnvioPendiente;
            formularioPendiente = null;
            botonEnvioPendiente = null;
            botonAceptar.disabled = true;

            if (
                !envioEnCurso &&
                botonParaRestaurarFoco &&
                document.documentElement.contains(botonParaRestaurarFoco)
            ) {
                botonParaRestaurarFoco.focus();
            }

            envioEnCurso = false;
        });

        botonAceptar.addEventListener('click', function () {
            if (botonAceptar.disabled || !formularioPendiente) return;

            detenerTemporizador();

            var formulario = formularioPendiente;
            var botonEnvio = botonEnvioPendiente;
            formulario.dataset.confirmacionAutorizada = '1';
            envioEnCurso = true;

            botonAceptar.disabled = true;
            textoAccion.textContent = 'Procesando…';
            contador.textContent = '';
            estado.textContent = 'Enviando la solicitud.';
            modal.hide();

            if (typeof formulario.requestSubmit === 'function') {
                if (botonEnvio && !botonEnvio.disabled) {
                    formulario.requestSubmit(botonEnvio);
                } else {
                    formulario.requestSubmit();
                }
            } else {
                HTMLFormElement.prototype.submit.call(formulario);
            }
        });

        return {
            abrir: function (formulario, botonEnvio) {
                formularioPendiente = formulario;
                botonEnvioPendiente = botonEnvio;
                envioEnCurso = false;
                accionPendiente = formulario.dataset.confirmacionAccion || 'Confirmar';
                titulo.textContent = formulario.dataset.confirmacionTitulo || 'Confirmar acción';
                mensaje.textContent = formulario.dataset.confirmacionMensaje ||
                    '¿Desea realizar esta acción?';

                segundosRestantes = 3;
                actualizarBloqueo();
                modal.show();
            }
        };
    }

    function formularioEsValido(formulario) {
        if (typeof formulario.checkValidity === 'function' && !formulario.checkValidity()) {
            if (typeof formulario.reportValidity === 'function') formulario.reportValidity();
            return false;
        }

        if (
            window.jQuery &&
            window.jQuery.fn &&
            typeof window.jQuery.fn.valid === 'function' &&
            !window.jQuery(formulario).valid()
        ) {
            return false;
        }

        return true;
    }

    function prepararConfirmacionesDestructivas(raiz) {
        if (!controladorConfirmacionDestructiva) {
            controladorConfirmacionDestructiva = crearControladorConfirmacionDestructiva();
        }
        if (!controladorConfirmacionDestructiva) return;

        raiz.querySelectorAll('form[data-confirmacion-destructiva]').forEach(function (formulario) {
            if (formulario.dataset.confirmacionDestructivaLista === '1') return;
            formulario.dataset.confirmacionDestructivaLista = '1';

            formulario.addEventListener('submit', function (e) {
                if (formulario.dataset.confirmacionAutorizada === '1') {
                    delete formulario.dataset.confirmacionAutorizada;
                    formulario.dataset.confirmacionEnviando = '1';
                    return;
                }

                if (formulario.dataset.confirmacionEnviando === '1') {
                    e.preventDefault();
                    return;
                }

                e.preventDefault();
                if (!formularioEsValido(formulario)) return;

                var botonEnvio = e.submitter ||
                    formulario.querySelector('button[type="submit"], input[type="submit"]');
                controladorConfirmacionDestructiva.abrir(formulario, botonEnvio);
            });
        });
    }

    function prepararConfirmaciones(raiz) {
        raiz.querySelectorAll('[data-confirmar]').forEach(function (el) {
            if (el.dataset.confirmarListo === '1') return;
            el.dataset.confirmarListo = '1';

            if (
                controladorConfirmacionDestructiva &&
                el.closest('form[data-confirmacion-destructiva]')
            ) {
                return;
            }

            el.addEventListener('click', function (e) {
                if (!window.confirm(el.dataset.confirmar)) e.preventDefault();
            });
        });
    }

    // ── Cascada territorial ─────────────────────────────────────────
    // La página incluye las listas completas y el navegador filtra cada nivel.
    //
    // Cada desplegable declara:
    //   data-cascada="<grupo>"  desplegables que trabajan juntos (residencia,
    //                           origen, filtro de reportes…)
    //   data-nivel="departamento|provincia|municipio"
    // y cada opción lleva el id de su padre en data-<nivel del padre>:
    // data-departamento en las provincias, data-provincia en los municipios.
    //
    // data-cascada-bloquear="no" en un hijo: mientras no se elija el padre
    // muestra todas sus opciones en lugar de quedar deshabilitado. Lo usa el
    // filtro de reportes, donde «sin departamento» significa «todo el país».
    var NIVELES_TERRITORIO = ['departamento', 'provincia', 'municipio'];

    function prepararCascadaTerritorial(raiz) {
        var grupos = {};

        (raiz || document)
            .querySelectorAll('select[data-cascada][data-nivel]')
            .forEach(function (select) {
                var nombre = select.dataset.cascada;
                var grupo = grupos[nombre] || (grupos[nombre] = {});
                grupo[select.dataset.nivel] = select;
            });

        Object.keys(grupos).forEach(function (nombre) {
            armarCascadaTerritorial(grupos[nombre]);
        });
    }

    function armarCascadaTerritorial(selects) {
        var niveles = NIVELES_TERRITORIO.filter(function (n) { return selects[n]; });
        if (niveles.length < 2) return;
        if (selects[niveles[0]].dataset.cascadaLista === '1') return;

        var capas = niveles.map(function (nivel, indice) {
            var select = selects[nivel];
            select.dataset.cascadaLista = '1';

            var padre = indice === 0 ? null : niveles[indice - 1];
            var vacia = select.querySelector('option[value=""]');

            return {
                select: select,
                // El último nivel de un grupo siempre bloquea; el intermedio sólo
                // si no se le dijo lo contrario.
                bloquea: select.dataset.cascadaBloquear !== 'no',
                textoVacio: vacia ? vacia.textContent : '—',
                inicial: select.value,
                opciones: Array.prototype.slice.call(select.options)
                    .filter(function (o) { return o.value !== ''; })
                    .map(function (o) {
                        return {
                            valor: o.value,
                            texto: o.textContent,
                            padre: padre ? (o.dataset[padre] || '') : ''
                        };
                    })
            };
        });

        function pintar(indice, seleccionado) {
            var capa = capas[indice];
            var valorPadre = capas[indice - 1].select.value;

            capa.select.innerHTML = '';

            var vacia = document.createElement('option');
            vacia.value = '';
            vacia.textContent = capa.textoVacio;
            capa.select.appendChild(vacia);

            var visibles = valorPadre
                ? capa.opciones.filter(function (o) { return o.padre === valorPadre; })
                : (capa.bloquea ? [] : capa.opciones);

            visibles.forEach(function (o) {
                var opcion = document.createElement('option');
                opcion.value = o.valor;
                opcion.textContent = o.texto;
                if (o.valor === seleccionado) opcion.selected = true;
                capa.select.appendChild(opcion);
            });

            capa.select.disabled = capa.bloquea && !valorPadre;
        }

        capas.forEach(function (capa, indice) {
            if (indice === capas.length - 1) return;

            capa.select.addEventListener('change', function () {
                for (var i = indice + 1; i < capas.length; i++) pintar(i, '');
            });
        });

        // Conserva la selección al volver del servidor con errores de validación.
        for (var i = 1; i < capas.length; i++) pintar(i, capas[i].inicial);
    }

    // ── Bloques que dependen de una casilla ───────────────────────────────
    // data-desactiva="#idDelBloque" en una casilla: al marcarla, ese <fieldset>
    // se oculta y queda deshabilitado, y un fieldset deshabilitado no envía
    // ninguno de sus campos. Así «es del mismo lugar donde vive» deja que el
    // servidor copie la residencia en el origen, en vez de que el navegador
    // mande una copia que después quede desincronizada.
    function prepararBloquesDependientes(raiz) {
        (raiz || document).querySelectorAll('[data-desactiva]').forEach(function (casilla) {
            if (casilla.dataset.desactivaListo === '1') return;
            casilla.dataset.desactivaListo = '1';

            var bloque = document.querySelector(casilla.dataset.desactiva);
            if (!bloque) return;

            function aplicar() {
                bloque.disabled = casilla.checked;
                bloque.classList.toggle('d-none', casilla.checked);
            }

            casilla.addEventListener('change', aplicar);
            aplicar();
        });
    }

    function inicializar(raiz) {
        raiz = raiz || document;

        raiz.querySelectorAll('[data-autocompletar]')
            .forEach(prepararAutocompletado);

        if (
            raiz instanceof Element &&
            raiz.matches('.linea-medicamento')
        ) {
            prepararSimulacionFifo(raiz);
        }

        raiz.querySelectorAll('.linea-medicamento')
            .forEach(prepararSimulacionFifo);

        prepararConfirmacionesDestructivas(raiz);
        prepararConfirmaciones(raiz);
        prepararFiltrosEntrada(raiz);
    }

    document.addEventListener('DOMContentLoaded', function () {
        inicializar(document);
        prepararTema();
        prepararEdad();
        prepararLineas();
        prepararCascadaTerritorial(document);
        prepararBloquesPorOpcion(document);
        prepararBloquesDependientes(document);
        prepararFechasRelacionadas();
        prepararEnlacesConPeriodo();

        var primero = document.querySelector('[data-foco-inicial]');
        if (primero) primero.focus();
    });
})();
