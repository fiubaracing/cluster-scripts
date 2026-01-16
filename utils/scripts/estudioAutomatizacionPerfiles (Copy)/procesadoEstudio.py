import os
import re
import glob
import matplotlib.pyplot as plt

# --- CONFIGURACIÓN DE RUTAS ---
PATH_RESULTADOS = "./resultados_estudio_E423"
# Usamos un patrón de búsqueda para ser flexibles con el nombre del archivo
# Buscamos dentro de postProcessing/FR/ (cualquier subcarpeta)/force.dat
BUSQUEDA_ARCHIVO = "postProcessing/FR/*/force.dat" 

def extraer_ultimas_fuerzas(path_file):
    """Extrae Drag (total_x) y Downforce (-total_z) de la última línea."""
    try:
        with open(path_file, 'r') as f:
            lineas = [l for l in f.readlines() if l.strip() and not l.startswith('#')]
            if not lineas: return None
            
            ultima_linea = lineas[-1]
            # Captura los valores dentro del primer paréntesis: (total_x total_y total_z)
            match = re.search(r'\(\s*([^\s]+)\s+([^\s]+)\s+([^\s]+)\s*\)', ultima_linea)
            if match:
                drag = float(match.group(1)) 
                downforce = -float(match.group(3)) # Invertimos el signo para Downforce
                return drag, downforce
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
    
    datos_por_malla[nombre_malla] = {"aoa": [], "downforce": [], "drag": []}
    
    # Listar ángulos (AoA_0, AoA_5, etc.)
    for nombre_aoa in os.listdir(path_malla):
        try:
            val_aoa = float(nombre_aoa.split('_')[1])
        except: continue
        
        # Buscamos el archivo usando glob para evitar problemas de rutas fijas
        pattern = os.path.join(path_malla, nombre_aoa, BUSQUEDA_ARCHIVO)
        archivos = glob.glob(pattern)
        
        if archivos:
            # Tomamos el primero que encuentre (usualmente hay solo uno)
            fuerzas = extraer_ultimas_fuerzas(archivos[0])
            if fuerzas:
                datos_por_malla[nombre_malla]["aoa"].append(val_aoa)
                datos_por_malla[nombre_malla]["drag"].append(fuerzas[0])
                datos_por_malla[nombre_malla]["downforce"].append(fuerzas[1])

# --- GENERAR GRÁFICOS ---
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
hay_datos = False

for malla, datos in datos_por_malla.items():
    if not datos["aoa"]:
        print(f" [!] Aviso: La carpeta {malla} no tiene datos procesables.")
        continue
    
    hay_datos = True
    # Ordenar por ángulo para que el gráfico no sea un zigzag
    puntos = sorted(zip(datos["aoa"], datos["downforce"], datos["drag"]))
    aoa_s, df_s, drag_s = zip(*puntos)
    
    ax1.plot(aoa_s, df_s, '-o', label=malla)
    ax2.plot(aoa_s, drag_s, '-s', label=malla)

if not hay_datos:
    print("[ERROR] No se encontró ningún archivo 'force.dat'.")
    exit()

# Formato Downforce
ax1.set_title("Downforce ($F_z$) vs AoA", fontweight='bold')
ax1.set_xlabel("Ángulo de Ataque [°]")
ax1.set_ylabel("Fuerza Vertical [N]")
ax1.grid(True, linestyle='--')
ax1.legend()

# Formato Drag
ax2.set_title("Drag ($F_x$) vs AoA", fontweight='bold')
ax2.set_xlabel("Ángulo de Ataque [°]")
ax2.set_ylabel("Fuerza de Arrastre [N]")
ax2.grid(True, linestyle='--')
ax2.legend()

plt.tight_layout()
plt.savefig("analisis_E423_final.png")
print("\n>>> Gráficos generados: 'analisis_E423_final.png'")
plt.show()
