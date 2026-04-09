const tomSelectElements = queryAll('.tom-select');

tomSelectElements.forEach((el) => {
  new TomSelect(el, {
    searchField: ['text'],
    sortField: [
      { field: '$order' },
      { field: 'text', direction: 'asc' }
    ],
    hideSelected: false,
    closeAfterSelect: true,
    placeholder: 'Search units...',
    // Prevent clearing selection with backspace/delete
    onDelete: function () { return false; },
    // Hide search in control and use plugin to show search in dropdown
    controlInput: null,
    // Use 'Drodown Input' to add search at the top of the list
    plugins: ['dropdown_input'],
    render: {
      option: function (data, escape) {
	const isSelected = this.items.indexOf(data.value) !== -1;
	const selectedClass = isSelected ? 'ts-option-custom selected-option' : 'ts-option-custom';
	return `<div class="${selectedClass}" data-value="${escape(data.value)}">${escape(data.text)}</div>`;
      },
    },
  });
});
