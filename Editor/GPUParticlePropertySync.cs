#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace GPUPS.Editor
{
    /// <summary>
    /// Syncs _ShapeRotation → _ShapeRotMatrix0/1/2 for GPU-side rotation matrix precomputation.
    /// Runs on EditorApplication.update to catch slider drags and undo/redo.
    /// </summary>
    [InitializeOnLoad]
    static class GPUParticlePropertySync
    {
        const string ShaderName = "GekikaraStore/GPUParticleSystem";

        static GPUParticlePropertySync()
        {
            EditorApplication.update += OnUpdate;
        }

        static void OnUpdate()
        {
            if (Selection.activeObject is not Material mat) return;
            if (mat.shader == null || mat.shader.name != ShaderName) return;
            if (!mat.HasProperty("_ShapeRotation") || !mat.HasProperty("_ShapeRotMatrix0")) return;
            SyncRotationMatrix(mat);
        }

        static void SyncRotationMatrix(Material mat)
        {
            Vector4 rot = mat.GetVector("_ShapeRotation");
            float rx = rot.x * Mathf.Deg2Rad;
            float ry = rot.y * Mathf.Deg2Rad;
            float rz = rot.z * Mathf.Deg2Rad;

            float sx = Mathf.Sin(rx), cx = Mathf.Cos(rx);
            float sy = Mathf.Sin(ry), cy = Mathf.Cos(ry);
            float sz = Mathf.Sin(rz), cz = Mathf.Cos(rz);

            // Same matrix layout as Core.hlsl rotation_matrix()
            var row0 = new Vector4(cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx, 0);
            var row1 = new Vector4(cx * sz, cx * cz, -sx, 0);
            var row2 = new Vector4(-sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx, 0);

            if (mat.GetVector("_ShapeRotMatrix0") == row0 &&
                mat.GetVector("_ShapeRotMatrix1") == row1 &&
                mat.GetVector("_ShapeRotMatrix2") == row2)
                return;

            mat.SetVector("_ShapeRotMatrix0", row0);
            mat.SetVector("_ShapeRotMatrix1", row1);
            mat.SetVector("_ShapeRotMatrix2", row2);
        }
    }
}
#endif
