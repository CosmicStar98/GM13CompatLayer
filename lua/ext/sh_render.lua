local render = render
local IMAT = FindMetaTable("IMaterial")

IMAT.GetMatrix = IMAT.GetMaterialMatrix
IMAT.GetVector = IMAT.GetMaterialVector
IMAT.SetMatrix = IMAT.SetMaterialMatrix
IMAT.GetFloat = IMAT.GetMaterialFloat
IMAT.GetInt = IMAT.GetMaterialInt
IMAT.GetString = IMAT.GetMaterialString
IMAT.GetTexture = IMAT.GetMaterialTexture
IMAT.SetFloat = IMAT.SetMaterialFloat
IMAT.SetInt = IMAT.SetMaterialInt
IMAT.SetString = IMAT.SetMaterialString
IMAT.SetTexture = IMAT.SetMaterialTexture
IMAT.SetVector = IMAT.SetMaterialVector

render.MaterialOverride = function(mat)
    SetMaterialOverride(mat)
end