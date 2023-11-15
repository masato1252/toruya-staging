import React from 'react';
import Select from 'react-select';

const ImageSelect = ({handleChange, options, ...props}) => {
  return (
    <Select
      options={options}
      components={{
        Option: CustomOption,
        SingleValue: CustomSingleValue,
      }}
      onChange={handleChange}
      options={options}
      {...props}
    />
  );
};

const CustomOption = ({ innerProps, label, data }) => (
  <div {...innerProps} className="my-4">
    <img
      src={data.image}
      alt={label}
      style={{ width: '200px', marginRight: '100px' }}
    />
  </div>
);

const CustomSingleValue = ({ children, ...props }) => (
  <div>
    <img
      src={props.data.image}
      alt={children}
      style={{ width: '200px', marginRight: '100px' }}
    />
    {children}
  </div>
);

export default ImageSelect;
