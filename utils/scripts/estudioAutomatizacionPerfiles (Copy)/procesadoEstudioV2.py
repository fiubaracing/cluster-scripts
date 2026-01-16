import os
import glob
import matplotlib.pyplot as plt

# --- CONFIGURACIÓN DE RUTAS ---
PATH_RESULTADOS = "./resultados_estudio_E423"
# Buscamos en postProcessing/LD/ (cualquier subcarpeta)/liftDrag.dat
BUSQUEDA_ARCHIVO = "postProcessing/LD/*/liftDrag.dat" 

def extraer_ultimo_ld(path_file):
    """Extrae totalLift (col 2) y drag (col 5) de la última línea."""
    try:
        with open(path_file, 'r') as f:
            # Filtramos líneas vacías y comentarios
            lineas = [l for l in f.readlines() if l.strip() and not l.startswith('#')]
            if not lineas: return None
            
            # Tomamos la última iteración
            ultima_linea = lineas[-1].split()
            
            # Según tu estructura: 
            # col 0: Time, col 1: totalLift, col 4: drag
            lift_coeff = -float(ultima_linea[1]) # Invertimos para Downforce positivo
            drag_coeff = float(ultima_linea[4])
            
            return lift_coeff, drag_coeff
    except Exception as e:
        print(f"   [!] Error leyendo {path_file}: {e}")
    return None

# --- PROCESAMIENTO ---
datos_por_malla = {}

if not os.path.exists(PATH_RESULTADOS):
    print(f"[ERROR] No se encontró la carpeta: {PATH_RESULTADOS}")
    exit()

for nombre_malla in os.listdir(PATH_RESULTADOS):
    path_malla = os.path.join(PATH_RESULTADOS, nombre_malla)
    if not os.path.isdir(path_malla): continue
    
    datos_por_malla[nombre_malla] = {"aoa": [], "cl": [], "cd": []}
    
    for nombre_aoa in os.listdir(path_malla):
        try:
            val_aoa = float(nombre_aoa.split('_')[1])
        except: continue
        
        pattern = os.path.join(path_malla, nombre_aoa, BUSQUEDA_ARCHIVO)
        archivos = glob.glob(pattern)
        
        if archivos:
            valores = extraer_ultimo_ld(archivos[0])
            if valores:
                datos_por_malla[nombre_malla]["aoa"].append(val_aoa)
                datos_por_malla[nombre_malla]["cl"].append(valores[0])
                datos_por_malla[nombre_malla]["cd"].append(valores[1])

# --- GENERAR GRÁFICOS ---
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
hay_datos = False

for malla, datos in datos_por_malla.items():
    if not datos["aoa"]: continue
    
    hay_datos = True
    # Ordenar por ángulo para evitar zigzags en el gráfico
    puntos = sorted(zip(datos["aoa"], datos["cl"], datos["cd"]))
    aoa_s, cl_s, cd_s = zip(*puntos)
    
    ax1.plot(aoa_s, cl_s, '-o', label=f"Cl - {malla}")
    ax2.plot(aoa_s, cd_s, '-s', label=f"Cd - {malla}")

if not hay_datos:
    print("[ERROR] No se encontraron archivos 'liftDrag.dat'.")
    exit()

# Formato Lift Coefficient (Downforce)
ax1.set_title("Coeficiente de Sustentación ($C_l$) vs AoA", fontweight='bold')
ax1.set_xlabel("Ángulo de Ataque [°]")
ax1.set_ylabel("$C_l$ (Downforce positivo)")
ax1.grid(True, linestyle='--')
ax1.legend()

# Formato Drag Coefficient
ax2.set_title("Coeficiente de Resistencia ($C_d$) vs AoA", fontweight='bold')
ax2.set_xlabel("Ángulo de Ataque [°]")
ax2.set_ylabel("$C_d$")
ax2.grid(True, linestyle='--')
ax2.legend()

plt.tight_layout()
plt.savefig("reporte_coeficientes_E423.png")
print("\n>>> Gráficos de coeficientes generados: 'reporte_coeficientes_E423.png'")
plt.show()
