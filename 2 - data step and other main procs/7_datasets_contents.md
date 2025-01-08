# `proc datasets`, `proc contents`

### `PROC DATASETS` and `PROC CONTENTS` in SAS

Both **`PROC DATASETS`** and **`PROC CONTENTS`** are powerful SAS procedures used for managing and investigating datasets. They have overlapping functionality, but they serve different primary purposes: `PROC CONTENTS` focuses on providing detailed metadata about datasets, while `PROC DATASETS` offers a broader range of dataset management capabilities, such as renaming, deleting, modifying variables, and much more.

Let's dive into each of these procedures:

---

## **`PROC DATASETS`** <a name="datasets"></a>

`PROC DATASETS` is a versatile procedure used to manage and manipulate datasets in a SAS library. Unlike `PROC CONTENTS`, which focuses on metadata, `PROC DATASETS` offers a wide range of dataset management tools, including renaming datasets, deleting datasets, renaming or deleting variables, modifying variable attributes, and more.

### Key Uses of `PROC DATASETS`:
1. **Manage Datasets**: Delete, rename, or copy datasets.
2. **Manage Variables**: Rename, label, or drop variables.
3. **Modify Variable Attributes**: Change formats, informats, or lengths of variables.
4. **Repair Datasets**: Fix certain issues, such as dataset indexing.
5. **List Datasets**: View datasets in a library.
6. **Manipulate Data Libraries**: Manage all datasets within a specific library.

### Syntax:
```sas
proc datasets library=libref <options>;
   modify dataset_name;
   rename old_var_name = new_var_name;
   label var_name = 'new_label';
   delete var_name;
   <other actions>;
quit;
```

- **`library`**: Specifies the SAS library that contains the datasets you want to manage.
- **`modify`**: Modify the attributes of the dataset, such as renaming variables, dropping variables, or changing labels.
- **`quit`**: Terminates the procedure.

### Example 1: Renaming a Dataset
```sas
proc datasets library=work;
   change old_dataset_name = new_dataset_name;
quit;
```
This code renames `old_dataset_name` to `new_dataset_name` in the `WORK` library.

### Example 2: Renaming and Deleting Variables
```sas
proc datasets library=work;
   modify dataset_name;
   rename old_var1 = new_var1;
   delete old_var2;
quit;
```
Here, `old_var1` is renamed to `new_var1`, and `old_var2` is deleted from the dataset.

### Example 3: Listing All Datasets in a Library
```sas
proc datasets library=sashelp;
   contents data=_all_;
quit;
```
This lists all the datasets in the `sashelp` library, showing basic metadata for each one.

### Example 4: Deleting a Dataset
```sas
proc datasets library=work;
   delete dataset_name;
quit;
```
Deletes `dataset_name` from the `WORK` library.

### Example 5: Modifying Formats for Variables
```sas
proc datasets library=work;
   modify dataset_name;
   format var_name dollar10.2;
quit;
```
This changes the format of `var_name` to a dollar format with 10 total characters and 2 decimal places.

---

## **`PROC CONTENTS`**  <a name="contents"></a>

`PROC CONTENTS` is designed to display metadata about datasets, such as variable names, types, formats, informats, and more. It provides a complete overview of the dataset's structure and attributes, but it doesn’t allow you to modify the dataset like `PROC DATASETS`.

### Key Uses of `PROC CONTENTS`:
1. **View Dataset Metadata**: Get detailed information about a dataset, including the number of variables, number of observations, variable types, lengths, labels, formats, and more.
2. **List All Datasets in a Library**: Retrieve a list of all datasets in a library.
3. **Retrieve Variable Information**: Access detailed information about individual variables.
4. **Export Metadata**: Output metadata into another dataset for further analysis.

### Syntax:
```sas
proc contents data=libref.dataset_name <options>;
run;
```

- **`data`**: Specifies the dataset for which you want to retrieve metadata.
- **`position`**: Displays variables in the order they are stored in the dataset rather than alphabetically.

### Example 1: Basic Metadata for a Dataset
```sas
proc contents data=sashelp.class;
run;
```
This displays metadata for the `sashelp.class` dataset, including variable names, types, formats, and lengths.

### Example 2: Display Variables in Storage Order
```sas
proc contents data=sashelp.class position;
run;
```
Displays metadata with variables in the order they are stored in the dataset.

### Example 3: Save Metadata to a New Dataset
```sas
proc contents data=sashelp.class out=metadata;
run;
```
This creates a new dataset `metadata` that contains information about the variables in the `sashelp.class` dataset.

### Example 4: List All Datasets in a Library
```sas
proc contents data=sashelp._all_;
run;
```
This lists all the datasets in the `sashelp` library, along with basic metadata about each dataset.

---

## **Differences Between `PROC DATASETS` and `PROC CONTENTS`**

| Feature                         | `PROC DATASETS`                                      | `PROC CONTENTS`                                   |
|----------------------------------|-----------------------------------------------------|---------------------------------------------------|
| **Primary Use**                  | Managing datasets and variables (rename, delete, etc.) | Viewing metadata about a dataset or library       |
| **Modify Datasets**              | Yes                                                 | No                                                |
| **Modify Variables**             | Yes (rename, delete, label, format)                 | No                                                |
| **List Datasets in a Library**   | Yes                                                 | Yes                                               |
| **View Metadata**                | Limited (via `CONTENTS` statement)                  | Yes                                               |
| **Export Metadata**              | No                                                  | Yes (using `OUT=` option)                         |

---

### **When to Use `PROC DATASETS` vs. `PROC CONTENTS`**

- **Use `PROC DATASETS`** when you need to **manage** datasets or variables, such as renaming, deleting, or modifying their attributes.
- **Use `PROC CONTENTS`** when you want to **view detailed metadata** about datasets and variables without making any changes. It’s a quick and effective way to explore the structure of a dataset.

Both procedures are essential tools for effective data management and exploration in SAS. While `PROC CONTENTS` is more commonly used for understanding the structure of a dataset, `PROC DATASETS` is essential when you need to modify or manage your data without creating new datasets each time.
