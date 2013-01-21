class Moped::Collection
  def upsert(id, change=nil)
    id = { _id: id }
    if change
      find(id).upsert change
    else
      insert id
    end
  end

  def without(field)
    find field => { '$exists' => false }
  end
end
