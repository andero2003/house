local Util = {}

function Util.getById(folder: Folder, id: number)
    for _, child in folder:GetChildren() do
        if child:GetAttribute('Id') == id then
            return child
        end
    end
end

return Util