import React, { useState, useEffect } from 'react';
import { WorkoutEntry } from '../../workoutData';
import {
  FiEdit2,
  FiTrash2,
  FiChevronUp,
  FiChevronDown,
  FiCheckCircle,
} from 'react-icons/fi';

type SortKey = keyof WorkoutEntry | null;
type SortDirection = 'asc' | 'desc';

interface WorkoutTableProps {
  data: WorkoutEntry[];
  onUpdateSet: (index: number, updatedEntry: WorkoutEntry) => void;
  onDeleteSet: (index: number) => void;
  onSort: (key: SortKey) => void;
  currentSortBy: SortKey;
  currentDirection: SortDirection;
  onMarkDone: (index: number) => void;
}

interface WorkoutRowProps {
  entry: WorkoutEntry;
  uniqueId: number;
  index: number;
  isEditing: boolean;
  onEditStart: (id: number, index: number) => void;
  onEditSave: (index: number, updatedEntry: WorkoutEntry) => void;
  onEditCancel: () => void;
  onDelete: (index: number) => void;
  onDone: (index: number) => void;
}

// ----------------------------------------------------------------------
// 1) Row
// ----------------------------------------------------------------------
const WorkoutRow: React.FC<WorkoutRowProps> = ({
  entry,
  index,
  uniqueId,
  isEditing,
  onEditStart,
  onEditSave,
  onEditCancel,
  onDelete,
  onDone,
}) => {
  const [editData, setEditData] = useState(entry);

  useEffect(() => {
    if (isEditing) setEditData(entry);
  }, [isEditing, entry]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type } = e.target;
    setEditData(prev => ({
      ...prev,
      [name]: type === 'number' ? Number(value) : value,
    }) as WorkoutEntry);
  };

  const handleDeleteClick = () => {
    if (window.confirm(`Delete: ${entry.exercise} (${entry.weightLbs} lbs)?`)) {
      onDelete(index);
    }
  };

  if (isEditing) {
    return (
      <tr className="bg-yellow-50 border-b">
        <td className="p-2">
          <input
            name="date"
            value={editData.date}
            onChange={handleChange}
            className="w-full text-sm p-1 border rounded"
          />
        </td>
        <td className="p-2">
          <input
            name="exercise"
            value={editData.exercise}
            onChange={handleChange}
            className="w-full text-sm p-1 border rounded"
          />
        </td>
        <td className="p-2">
          <input
            type="number"
            name="set"
            value={editData.set}
            onChange={handleChange}
            className="w-full text-sm p-1 border rounded"
          />
        </td>
        <td className="p-2">
          <input
            type="number"
            name="weightLbs"
            value={editData.weightLbs}
            onChange={handleChange}
            className="w-full text-sm p-1 border rounded"
          />
        </td>
        <td className="p-2">
          <input
            type="number"
            name="reps"
            value={editData.reps}
            onChange={handleChange}
            className="w-full text-sm p-1 border rounded"
          />
        </td>
        <td className="p-2">
          <input
            name="muscleGroup"
            value={editData.muscleGroup}
            onChange={handleChange}
            className="w-full text-sm p-1 border rounded"
          />
        </td>
        <td className="p-2">
          <input
            name="notes"
            value={editData.notes}
            onChange={handleChange}
            className="w-full text-sm p-1 border rounded"
          />
        </td>
        {/* empty Done + Edit/Delete cols while editing */}
        <td className="p-2" />
        <td className="p-2 flex space-x-2">
          <button
            onClick={() => onEditSave(index, editData)}
            className="text-white bg-green-500 hover:bg-green-600 px-2 py-1 rounded text-xs"
          >
            Save
          </button>
          <button
            onClick={onEditCancel}
            className="text-white bg-red-500 hover:bg-red-600 px-2 py-1 rounded text-xs"
          >
            Cancel
          </button>
        </td>
        <td className="p-2" />
      </tr>
    );
  }

  return (
    <tr className="border-b hover:bg-gray-50 transition-colors duration-150">
      <td className="p-3 text-sm font-medium text-gray-900">{entry.date}</td>
      <td className="p-3 text-sm font-bold text-indigo-600">
        {entry.exercise}
      </td>
      <td className="p-3 text-sm text-gray-500">{entry.set || 1}</td>
      <td className="p-3 text-sm text-gray-900">{entry.weightLbs} lbs</td>
      <td className="p-3 text-sm text-gray-500">{entry.reps}</td>
      <td className="p-3 text-sm text-gray-600">
        <span className="inline-flex items-center rounded-full bg-blue-100 px-3 py-0.5 text-xs font-medium text-blue-800">
          {entry.muscleGroup}
        </span>
      </td>
      <td className="p-3 text-sm text-gray-500 italic">
        {entry.notes || '-'}
      </td>
      <td className="p-3 text-sm text-gray-500">
        <button
          onClick={() => onDone(index)}
          className="text-gray-400 hover:text-green-600 transition-colors"
          aria-label="Mark done"
          title="Mark done"
        >
          <FiCheckCircle size={16} />
        </button>
      </td>
      <td className="p-3 text-sm text-gray-500">
        <button
          onClick={() => onEditStart(uniqueId, index)}
          className="text-gray-400 hover:text-indigo-600 transition-colors mr-2"
          aria-label="Edit set"
        >
          <FiEdit2 size={16} />
        </button>
      </td>
      <td className="p-3 text-sm text-gray-500">
        <button
          onClick={handleDeleteClick}
          className="text-gray-400 hover:text-red-600 transition-colors"
          aria-label="Delete set"
        >
          <FiTrash2 size={16} />
        </button>
      </td>
    </tr>
  );
};

// ----------------------------------------------------------------------
// 2) Sortable header
// ----------------------------------------------------------------------
const SortableHeader: React.FC<{
  label: string;
  sortKey: SortKey;
  currentSortBy: SortKey;
  currentDirection: SortDirection;
  onSort: (key: SortKey) => void;
}> = ({ label, sortKey, currentSortBy, currentDirection, onSort }) => {
  const isSorted = currentSortBy === sortKey;

  const renderSortIcon = () => {
    if (!isSorted)
      return (
        <FiChevronUp
          size={14}
          className="opacity-0 group-hover:opacity-50 transition-opacity"
        />
      );
    if (currentDirection === 'asc')
      return <FiChevronUp size={14} className="text-indigo-600" />;
    return <FiChevronDown size={14} className="text-indigo-600" />;
  };

  return (
    <th
      className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider cursor-pointer hover:bg-gray-200 transition-colors"
      onClick={() => onSort(sortKey)}
    >
      <div className="flex items-center group">
        <span className="mr-1">{label}</span>
        {renderSortIcon()}
      </div>
    </th>
  );
};

// ----------------------------------------------------------------------
// 3) Table
// ----------------------------------------------------------------------
const WorkoutTable: React.FC<WorkoutTableProps> = ({
  data,
  onUpdateSet,
  onDeleteSet,
  onSort,
  currentSortBy,
  currentDirection,
  onMarkDone,
}) => {
  const [editingId, setEditingId] = useState<number | null>(null);
  const [, setEditingData] = useState<WorkoutEntry | null>(null);

  const handleEditStart = (id: number, index: number) => {
    setEditingId(id);
    setEditingData(data[index]);
  };

  const handleEditSave = (index: number, updatedEntry: WorkoutEntry) => {
    onUpdateSet(index, updatedEntry);
    setEditingId(null);
  };

  const handleEditCancel = () => setEditingId(null);

  return (
    <div className="overflow-x-auto shadow-xl rounded-xl">
      <table className="min-w-full divide-y divide-gray-200">
        <thead>
          <tr className="bg-gray-100">
            {[
              { label: 'Date', sortKey: 'date' as SortKey },
              { label: 'Exercise', sortKey: 'exercise' as SortKey },
              { label: 'Set', sortKey: 'set' as SortKey },
              { label: 'Weight (lbs)', sortKey: 'weightLbs' as SortKey },
              { label: 'Reps', sortKey: 'reps' as SortKey },
              { label: 'Muscle Group', sortKey: 'muscleGroup' as SortKey },
            ].map(col => (
              <SortableHeader
                key={col.label}
                label={col.label}
                sortKey={col.sortKey}
                currentSortBy={currentSortBy}
                currentDirection={currentDirection}
                onSort={onSort}
              />
            ))}
            <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">
              Notes
            </th>
            <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">
              Done
            </th>
            <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">
              Edit
            </th>
            <th className="p-3 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">
              Del
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {data.map((workout, index) => {
            const uniqueId = workout.id;
            return (
              <WorkoutRow
                key={uniqueId}
                entry={workout}
                index={index}
                uniqueId={uniqueId}
                isEditing={editingId === uniqueId}
                onEditStart={handleEditStart}
                onEditSave={handleEditSave}
                onEditCancel={handleEditCancel}
                onDelete={onDeleteSet}
                onDone={onMarkDone}
              />
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

export default WorkoutTable;
