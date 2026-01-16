import os
import glob
import matplotlib.pyplot as plt

# --- CONFIGURACIÓN DE RUTAS ---
PATH_RESULTADOS = "./resultados_estudio_E423"
BUSQUEDA_ARCHIVO = "postProcessing/LD/*/liftDrag.dat" 

# --- DATOS DEL PAPER (Run 850 & 851, Re = 302300) ---
# He ordenado los datos por alfa para que la línea del gráfico sea continua
paper_data = {
    "alpha": [-4.48, -3.38, -2.32, -0.78, 0.74, 2.28, 3.80, 5.33, 6.86, 8.40, 9.89, 11.42, 12.96],
    "cl": [0.275, 0.414, 0.724, 0.877, 1.023, 1.169, 1.304, 1.431, 1.556, 1.668, 1.769, 1.870, 1.944],
    "cd": [0.0623, 0.0518, 0.0180, 0.0172, 0.0184, 0.0193, 0.0199, 0.0201, 0.0219, 0.0237, 0.0259, 0.0279, 0.0319]
}

def extraer_ultimo_ld(path_file):
    """Extrae totalLift y drag de la última línea del archivo."""
    try:
        with open(path_file, 'r') as f:
            lineas = [l for l in f.readlines() if l.strip() and not l.startswith('#')]
            if not lineas: return None
            # Estructura: Time(0), totalLift(1), ..., drag(4)
            ultima = lineas[-1].split()
            cl = -float(ultima[1]) # Invertimos Downforce a Sustentación positiva
            cd = float(ultima[4])
            return cl, cd
    except Exception as e:
        print(f"   [!] Error en {path_file}: {e}")
    return None

# --- PROCESAMIENTO DE SIMULACIONES ---
datos_por_malla = {}

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
fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(18, 6))

# 1. Graficar datos del Paper (Referencia)
ax1.plot(paper_data["alpha"], paper_data["cl"], 'k--', label="Paper (Run 850/851)", alpha=0.7)
ax2.plot(paper_data["alpha"], paper_data["cd"], 'k--', label="Paper (Run 850/851)", alpha=0.7)
ax3.plot(paper_data["cd"], paper_data["cl"], 'k--', label="Paper (Run 850/851)", alpha=0.7)

# 2. Graficar datos de CFD
for malla, datos in datos_por_malla.items():
    if not datos["aoa"]: continue
    puntos = sorted(zip(datos["aoa"], datos["cl"], datos["cd"]))
    aoa_s, cl_s, cd_s = zip(*puntos)
    
    ax1.plot(aoa_s, cl_s, '-o', label=f"CFD: {malla}")
    ax2.plot(aoa_s, cd_s, '-s', label=f"CFD: {malla}")
    ax3.plot(cd_s, cl_s, '-^', label=f"CFD: {malla}")

# Formato Gráfico 1: Cl vs AoA
ax1.set_title("Coeficiente de Sustentación ($C_l$)", fontweight='bold')
ax1.set_xlabel("Ángulo de Ataque [°]")
ax1.set_ylabel("$C_l$")
ax1.grid(True, linestyle='--')
ax1.legend()

# Formato Gráfico 2: Cd vs AoA
ax2.set_title("Coeficiente de Resistencia ($C_d$)", fontweight='bold')
ax2.set_xlabel("Ángulo de Ataque [°]")
ax2.set_ylabel("$C_d$")
ax2.grid(True, linestyle='--')
ax2.legend()

# Formato Gráfico 3: Polar de Arrastre (Cl vs Cd)
ax3.set_title("Polar de Arrastre ($C_l$ vs $C_d$)", fontweight='bold')
ax3.set_xlabel("$C_d$ (Resistencia)")
ax3.set_ylabel("$C_l$ (Sustentación)")
ax3.grid(True, linestyle='--')
ax3.legend()

plt.suptitle(f"Validación Eppler 423 - Reynolds {paper_data.get('re', 302300)}", fontsize=14)
plt.tight_layout()
plt.savefig("validacion_aerodinamica_E423.png", dpi=300)
plt.show()

print("\n>>> Reporte de validación generado: 'validacion_aerodinamica_E423.png'")
