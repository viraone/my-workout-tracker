import React from 'react';

interface StatCardProps {
  title: string;
  value: string | number;
  unit?: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, unit }) => {
  return (
    <div className="bg-white p-5 rounded-xl shadow-md border border-gray-200 w-full">
      <p className="text-sm font-medium text-gray-500 uppercase tracking-wider mb-1">{title}</p>
      <p className="text-3xl font-extrabold text-gray-900">
        {value}
        {unit && <span className="text-xl font-medium text-gray-500 ml-1">{unit}</span>}
      </p>
    </div>
  );
};

export default StatCard;