# generar_fotos.py
import sys
import os
from paraview.simple import *

# Recibimos la ruta del caso como argumento
case_path = sys.argv[1]
output_dir = sys.argv[2]
foam_file = os.path.join(case_path, "case.foam")

# Crear un archivo .foam vacío para que ParaView lo reconozca
if not os.path.exists(foam_file):
    open(foam_file, 'w').close()

# Cargar el caso
case = OpenFOAMReader(FileName=foam_file)
case.MeshRegions = ['internalMesh']

# Configurar la vista
view = GetActiveViewOrCreate('RenderView')
view.ViewSize = [1600, 900]
view.OrientationAxesVisibility = 0 # Ocultar ejes para mayor claridad

# --- FOTO 1: VELOCIDAD (U) ---
display = Show(case, view)
ColorBy(display, ('POINTS', 'U'))
u_lut = GetColorTransferFunction('U')
u_lut.ApplyPreset('Jet', (True)) # Mapa de colores clásico
view.ResetCamera()
# Zoom al perfil (ajustar según tus coordenadas)
view.CameraParallelScale = 0.8 
SaveScreenshot(os.path.join(output_dir, "contorno_velocidad.png"), view)

# --- FOTO 2: MALLA (Detalle) ---
display.Representation = 'Surface With Edges'
ColorBy(display, None) # Color sólido para ver la malla
view.CameraParallelScale = 0.2 # Zoom más cerrado al perfil
SaveScreenshot(os.path.join(output_dir, "detalle_mallado.png"), view)

print(f"   [OK] Imágenes generadas en {output_dir}")
