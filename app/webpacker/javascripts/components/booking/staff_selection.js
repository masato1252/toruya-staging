"use strict";

import React from "react";

const StaffSelection = ({
  availableStaffs,
  selectedStaffId,
  onStaffSelect,
  resetValuesCallback,
  i18n
}) => {
  if (!availableStaffs || availableStaffs.length <= 1) {
    return null; // Don't show if there's only one or no staff
  }

  const { edit } = i18n;

  return (
    <div className="staff-selection-container">
      <div className="section-header">
        <h3>
          {i18n.staff_selection.title}
          {resetValuesCallback && selectedStaffId !== null && <a href="#" className="edit" onClick={resetValuesCallback}>{edit}</a>}
        </h3>
        <p>
          {i18n.staff_selection.description}
        </p>
      </div>

      <div className="staff-options">
        <div
          className={`staff-option ${selectedStaffId === null ? 'selected' : ''}`}
          onClick={() => onStaffSelect('any_staff')}
        >
          {i18n.staff_selection.any_staff}
        </div>

        {availableStaffs.map(staff => (
          <div
            key={staff.id}
            className={`staff-option ${selectedStaffId === staff.id ? 'selected' : ''}`}
            onClick={() => onStaffSelect(staff.id)}
          >
            {staff.name}
          </div>
        ))}
      </div>
    </div>
  );
};

export default StaffSelection;