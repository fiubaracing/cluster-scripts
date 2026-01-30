import os, shutil, subprocess, csv, re

# --- RUTAS VM ---
BASE_DIR = "/home/introcfd/Desktop/perfiles23"
CASE_DIR = os.path.join(BASE_DIR, "perfiles2E")
GEOM_DIR = os.path.join(BASE_DIR, "geometrias")
RESULT_DIR = os.path.join(BASE_DIR, "resultados")
CSV_PATH = os.path.join(RESULT_DIR, "resumen_aerodinamico.csv")

def extraer_lift_drag():
    """Limpia paréntesis y extrae datos."""
    path = os.path.join(CASE_DIR, "postProcessing/fuerzaTotal/0/force.dat")
    try:
        with open(path, 'r') as f:
            lines = [l for l in f.readlines() if not l.startswith('#')]
            if lines:
                # SOLUCIÓN: Quitamos paréntesis para evitar el ValueError
                clean = lines[-1].replace('(', '').replace(')', '')
                parts = clean.split()
                drag, lift = float(parts[1]), float(parts[2])
                return lift, drag, (abs(lift/drag) if drag != 0 else 0)
    except: pass
    return "N/A", "N/A", "N/A"

def run_loop():
    configs = sorted([d for d in os.listdir(GEOM_DIR) if os.path.isdir(os.path.join(GEOM_DIR, d))])
    os.makedirs(RESULT_DIR, exist_ok=True)

    for config in configs:
        print(f"\n>>> TRABAJANDO EN: {config}")
        
        # 1. LIMPIEZA TOTAL (Manual)
        for f in ["constant/polyMesh", "postProcessing"]:
            shutil.rmtree(os.path.join(CASE_DIR, f), ignore_errors=True)

        # 2. SWAP STLs
        for stl in ["mainPlane.stl", "flap1.stl"]:
            shutil.copy(os.path.join(GEOM_DIR, config, stl), os.path.join(CASE_DIR, "constant/triSurface"))

        # 3. EJECUCIÓN LOCAL (Malla + Solver)
        # Aquí ejecutamos directamente los binarios de HELYX/OpenFOAM
        print("   [Solver] Corriendo simulación local...")
        subprocess.run(["cartesian2DMesh"], cwd=CASE_DIR)
        subprocess.run(["helyxSolve"], cwd=CASE_DIR)

        # 4. FOTOS (Adaptado para VM)
        subprocess.run(["pvpython", "generar_fotos_vm.py", CASE_DIR, os.path.join(RESULT_DIR, config)], cwd=BASE_DIR)

        # 5. DATOS
        cl, cd, l_d = extraer_lift_drag()
        with open(CSV_PATH, 'a', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([config, cl, cd, l_d])
