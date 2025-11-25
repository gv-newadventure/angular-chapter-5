
            // -------- Result set 2: unmapped source fields --------
            if (reader.NextResult())
            {
                while (reader.Read())
                {
                    var unmapped = new UnmappedFieldDto
                    {
                        FieldNumber = reader.GetInt32(reader.GetOrdinal("FieldNumber")),
                        FieldLabel = reader.GetString(reader.GetOrdinal("FieldLabel")),
                        FieldDataType = reader.IsDBNull(reader.GetOrdinal("FieldDataType"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("FieldDataType"))
                    };

                    result.UnmappedSourceFields.Add(unmapped);
                }
            }




            public class RemapDetailsDto
{
    public IList<RemapFieldDto> FieldRules { get; set; }
    public IList<UnmappedFieldDto> UnmappedSourceFields { get; set; }
}
