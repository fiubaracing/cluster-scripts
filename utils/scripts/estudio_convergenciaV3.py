import os
import subprocess
import shutil

# --- CONFIGURACIÓN ---
# Prueba con dos resoluciones extremas para notar el cambio
resoluciones = [(10, 1, 5), (20, 1, 10), (40, 1 , 20), (80, 1, 40), (160, 1, 80)] 
N_PROCS = 4

import re

def update_blockmesh_simple(nx, ny, nz):
    ruta = "system/blockMeshDict"
    if not os.path.exists(ruta):
        print(f"ERROR: No se encuentra el archivo en {ruta}")
        exit(1)

    with open(ruta, 'r') as f:
        lineas = f.readlines()
    
    # Esta es la nueva línea que queremos insertar
    nueva_resolucion = f"({nx} {ny} {nz})"
    encontrado = False
    
    with open(ruta, 'w') as f:
        for linea in lineas:
            # Buscamos una línea que contenga 'hex' y los vértices '(0 1 2 3 4 5 6 7)'
            # sin importar cuántos espacios haya entre medio.
            if re.search(r"hex\s+\(\s*0\s+1\s+2\s+3\s+4\s+5\s+6\s+7\s*\)", linea):
                # Reemplazamos el segundo paréntesis (la resolución) por los nuevos valores
                # Buscamos el patrón de tres números entre paréntesis: (\d+ \d+ \d+)
                linea_modificada = re.sub(r"\(\s*\d+\s+\d+\s+\d+\s*\)", nueva_resolucion, linea, count=1)
                f.write(linea_modificada)
                encontrado = True
                print(f"DEBUG: ¡Línea encontrada! Nueva resolución: {nueva_resolucion}")
            else:
                f.write(linea)
    
    if not encontrado:
        print("\n--- ERROR DE BÚSQUEDA ---")
        print("No se pudo encontrar la definición del bloque en blockMeshDict.")
        print("Por favor, verifica que la línea empiece con 'hex (0 1 2 3 4 5 6 7)'.")
        exit(1)

# --- BUCLE PRINCIPAL ---
for nx, ny, nz in resoluciones:
    print("\n" + "="*80)
    print(f" INICIANDO NUEVA SIMULACIÓN: RESOLUCIÓN {nx}x{nz}")
    print("="*80)

    # 1. Modificar el archivo y mostrarlo en pantalla para estar seguros
    update_blockmesh_simple(nx, ny, nz)
    
    # 2. Limpieza TOTAL de la carpeta para no arrastrar mallas viejas
    print(">> Limpiando directorios...")
    for d in ["0", "constant/polyMesh", "postProcessing"] + [f"processor{i}" for i in range(N_PROCS)]:
        if os.path.exists(d):
            if os.path.isfile(d): os.remove(d)
            else: shutil.rmtree(d)

    # 3. Generación de Malla (Paso a paso con verificación)
    print(">> Ejecutando blockMesh...")
    subprocess.run("blockMesh", shell=True, check=True)
    
    print(">> Ejecutando decompose y helyxHexMesh (Paralelo)...")
    subprocess.run("decomposePar", shell=True, check=True)
    subprocess.run(f"mpirun -n {N_PROCS} helyxHexMesh -parallel", shell=True, check=True)
    
    print(">> Reconstruyendo malla...")
    subprocess.run("reconstructParMesh -constant", shell=True, check=True)

    # 4. VERIFICACIÓN MANUAL EN EL LOG
    # Esto te va a decir en la cara cuántas celdas tiene la malla recién hecha
    print("\nVERIFICACIÓN DE MALLA:")
    res = subprocess.run("checkMesh | grep 'cells:'", shell=True, capture_output=True, text=True)
    print(f"RESULTADO: {res.stdout.strip()}")
    print("-" * 40)

    # 5. Configurar y Correr
    print(">> Ejecutando caseSetup...")
    subprocess.run("caseSetup", shell=True, check=True)
    
    print(">> Resolviendo (Parallel Solve)...")
    subprocess.run("rm -rf processor*", shell=True)
    subprocess.run("decomposePar", shell=True, check=True)
    subprocess.run(f"mpirun -n {N_PROCS} helyxSolve -parallel", shell=True, check=True)

    # 6. Guardar con nombre único
    nombre_carpeta = f"SIM_RES_{nx}x{nz}"
    os.makedirs(nombre_carpeta, exist_ok=True)
    if os.path.exists("postProcessing"):
        shutil.move("postProcessing", os.path.join(nombre_carpeta, "postProcessing"))
    
    # IMPORTANTE: Copiamos la malla a la carpeta del resultado para verla después
    shutil.copytree("constant/polyMesh", os.path.join(nombre_carpeta, "polyMesh"))
    
    print(f"\n>> FINALIZADO CASO {nx}x{nz}. Datos guardados en {nombre_carpeta}")
